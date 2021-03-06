package HatedaEditor;

use utf8;
use Moose;
use MooseX::ClassAttribute;
use Curses::UI;
use File::Temp;
use WWW::HatenaDiary;
use HatedaEditor::ConfigLoader;
use HatedaEditor::Logic::Common;
use HatedaEditor::Logic::Viewer;
use HatedaEditor::Logic::GroupListbox;
use Encode;
use HTTP::Cookies;

our $VERSION = '0.003';
our $DEBUG = 0 || $ENV{DEBUG_HATEDAEDITOR};

class_has 'win'           => ( is => 'rw', );
class_has 'viewer'        => ( is => 'rw', );
class_has 'group_listbox' => ( is => 'rw', );
class_has 'menu'          => ( is => 'rw', );
class_has 'checkbox'      => ( is => 'rw', );
class_has 'cui'           => (
    is      => 'rw',
    default => sub {
        return Curses::UI->new(
            -color_support => 1,
            -language      => "english",
            -debug         => $DEBUG,
        );
    }
);
class_has 'api' => ( is => 'rw', );
class_has 'current_group' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'NONE',
);

class_has 'config' => ( is => 'rw', );

sub BUILD {
    my $self = shift;
    $self->_load_config;
    $self->_setup_api( __PACKAGE__->config->{default_group} );
    $self->_setup_ui;

    __PACKAGE__->viewer->focus();
    __PACKAGE__->cui->leave_curses;
}

no Moose;

sub _load_config {
    my $self          = shift;
    my $config_loader = HatedaEditor::ConfigLoader->instance;
    $self->config( $config_loader->load );
}

sub _setup_api {
    my $self  = shift;
    my $group = shift;

    if ( $group eq 'NONE' ) {
        $group = undef;
    }

    my $timeout     = $self->config->{cookie} || 3000;
    my $cookie_file = $self->config->{cookie} || 'cookie.txt';

    my $cookies = HTTP::Cookies->new(
        file     => $cookie_file,
        autosave => 1,
    );
    $self->_setup_proxy;
    my $diary = WWW::HatenaDiary->new(
        {   username => $self->config->{username},
            password => $self->config->{password},
            group    => $group,
            mech_opt => {
                timeout    => $timeout,
                cookie_jar => $cookies,
                env_proxy  => 1,
            },
        }
    );
    if ( !$diary->is_loggedin ) {
        $diary->login(
            {   username => $self->config->{username},
                password => $self->config->{password},
            }
        );
    }
    __PACKAGE__->api($diary);
}

sub _setup_proxy {
    my $proxy = __PACKAGE__->config->{proxy};
    $ENV{HTTP_PROXY} = $proxy if $proxy;
}

sub _setup_ui {
    my $self = shift;
    $self->_setup_cui;
    $self->_setup_window;
    $self->_setup_menu;
    $self->_setup_viewer;
    $self->_setup_trivial_checkbox;
}

sub create_group_listbox {
    my $self = shift;

    my @group_list = split /\s/, __PACKAGE__->config->{group_list};
    push @group_list, 'NONE';
    my $group_listbox = __PACKAGE__->win->add(
        'listbox',
        'Listbox',
        -border     => 1,
        -values     => \@group_list,
        -wraparound => 1,
        -x          => 5,
        -y          => 2,
        -width      => 50,
        -height     => 5,
        -onchange   => \&HatedaEditor::Logic::GroupListbox::onchange,
    );
    __PACKAGE__->group_listbox($group_listbox);

    $self->_setup_group_listbox_binding();

    return $group_listbox;
}

sub _setup_group_listbox_binding {
    my $self = shift;
    __PACKAGE__->group_listbox->set_binding(
        sub {
            __PACKAGE__->win->delete('listbox');
            __PACKAGE__->win->draw;
        },
        'q'
    );

}

sub _setup_cui {
    my $self = shift;
    $self->_setup_cui_binding;
}

sub _setup_cui_binding {
    my $c = __PACKAGE__->cui;
    $c->set_binding( \&HatedaEditor::Logic::Common::quit, "\cq" );
    $c->set_binding( \&HatedaEditor::Logic::Common::quit, "\cc" );
    $c->set_binding( sub { __PACKAGE__->menu->focus() },   'm' );
    $c->set_binding( sub { __PACKAGE__->viewer->focus() }, 'v' );
    $c->set_binding(
        sub {
            __PACKAGE__->create_group_listbox()->focus();
        },
        'g'
    );
}

sub _setup_menu {
    my $self = shift;
    my @menu = (
        {   -label => 'File',
            -submenu =>
                [ { -label => 'Exit      ^Q', -value => \&exit_dialog } ]
        },
        {   -label   => 'Help',
            -submenu => [
                {   -label => 'Help      ',
                    -value => \&HatedaEditor::Logic::Common::show_help
                },
                {   -label => 'About     ',
                    -value => \&HatedaEditor::Logic::Common::show_about
                },
            ]
        }
    );
    my $menu = __PACKAGE__->cui->add(
        'menu', 'Menubar',
        -menu => \@menu,
        -fg   => "black",
        -bg   => "white",
    );
    __PACKAGE__->menu($menu);
}

# refactor
sub exit_dialog {
    my $return = __PACKAGE__->cui->dialog(
        -message => "Do you really want to quit?",
        -title   => "Are you sure???",
        -buttons => [ 'yes', 'no' ],
    );

    exit(0) if $return;
}

sub _setup_window {
    my $self = shift;
    __PACKAGE__->win(
        __PACKAGE__->cui->add(
            'main', 'Window',
            -border => 1,
            -y      => 1,
            -bfg    => 'red',
        )
    );
}

sub _setup_viewer {
    my $self = shift;
    $self->viewer(
        __PACKAGE__->win->add(
            "text", "TextViewer",
            -text => "\n
        HatedaEditor - CUI Hatena Editor \n
               version 0.003\n
                  by Dann \n
    HatedaEditor is open source and freely distributable \n
        hit  ? for help information \n
"
        )
    );

    $self->_setup_viewer_binding;
}

sub _setup_trivial_checkbox {
    my $self = shift;
    $self->checkbox(
        __PACKAGE__->win->add(
            'trivial_checkbox', 'Checkbox',
            -label   => 'trivial update?',
            -checked => 0,
        )
    );

}

sub _setup_viewer_binding {
    my $self = shift;
    my $v    = __PACKAGE__->viewer;
    $v->set_binding( \&HatedaEditor::Logic::Common::show_help,      '?' );
    $v->set_binding( \&HatedaEditor::Logic::Viewer::edit,           'e' );
    $v->set_binding( \&HatedaEditor::Logic::Viewer::edit_new_entry, 'c' );
    $v->set_binding( \&HatedaEditor::Logic::Common::quit,           'q' );
    $v->set_binding( sub { $v->focus; },         'v' );
    $v->set_binding( sub { $v->cursor_down },    'j' );
    $v->set_binding( sub { $v->cursor_up },      'k' );
    $v->set_binding( sub { $v->cursor_right },   'l' );
    $v->set_binding( sub { $v->cursor_left },    'h' );
    $v->set_binding( sub { $v->cursor_to_home }, '0' );
    $v->set_binding( sub { $v->cursor_to_end },  'G' );

}

sub run {
    my $self = shift;
    __PACKAGE__->cui->reset_curses;
    __PACKAGE__->cui->mainloop;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

HatedaEditor -

=head1 SYNOPSIS

  use HatedaEditor;

=head1 DESCRIPTION

HatedaEditor is

=head1 AUTHOR

dann E<lt>techmemo@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
