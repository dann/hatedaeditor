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

our $VERSION = '0.01';

class_has 'win'           => ( is => 'rw', );
class_has 'viewer'        => ( is => 'rw', );
class_has 'group_listbox' => ( is => 'rw', );
class_has 'menu'          => ( is => 'rw', );
class_has 'cui'           => (
    is      => 'rw',
    default => sub {
        return Curses::UI->new(
            -color_support => 1,
            -language      => "japanese"
        );
    }
);
class_has 'api' => ( is => 'rw', );
class_has 'current_group' => (
    is  => 'rw',
    isa => 'Str'
);

has 'config' => ( is => 'rw', );

sub BUILD {
    my $self = shift;
    $self->_load_config;
    $self->_setup_api;
    $self->_setup_ui;
}

sub _load_config {
    my $self          = shift;
    my $config_loader = HatedaEditor::ConfigLoader->instance;
    $self->config( $config_loader->load );
}

sub _setup_api {
    my $self  = shift;
    my $diary = WWW::HatenaDiary->new(
        {   username => $self->config->{username},
            password => $self->config->{password},
        }
    );
    if ( !$diary->is_loggedin ) {

        $diary->login(
            {   username => $self->config->{username},
                password => $self->config->{password},
            }
        );
    }
    $self->api($diary);
}

sub _setup_ui {
    my $self = shift;
    $self->_setup_cui;
    $self->_setup_window;
    $self->_setup_menu;
    $self->_setup_viewer;
    $self->_setup_group_listbox;

    # focusするタイミングを調べる
    __PACKAGE__->viewer->focus();
    __PACKAGE__->cui->leave_curses;
}

sub _setup_group_listbox {
    my $group_list = [ 'catalyst', 'dann', 'NONE' ];
    my $group_listbox = __PACKAGE__->win->add(
        'listbox',
        'Listbox',
        -border     => 1,
        -values     => $group_list,
        -wraparound => 1,
        -x          => 5,
        -y          => 2,
        -width      => 50,
        change_cb   => sub {

            #    my $group = shift;
            #HatedaEditor->current_group($group);
            #HatedaEditor->win->delete('listbox');
        },

        -onchange => \&HatedaEditor::Logic::GroupListbox::onchange,
    );
    __PACKAGE__->group_listbox($group_listbox);

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
            __PACKAGE__->group_listbox->focus();
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
        -fg   => "blue",
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
    my $help_label = __PACKAGE__->win->add(
        'helplabel', 'Label',
        -bold => 1,
        -text => "Help: hit '?'",

        #-x => 32,
        #    -y => 0,

    );
    $help_label->draw;

}

sub _setup_viewer {
    my $self = shift;
    $self->viewer(
        $self->win->add(
            "text", "TextViewer",
            -text => "Hatena Diary Editor! Show help with '?';\n",
        )
    );

    $self->_setup_viewer_binding;
}

sub _setup_viewer_binding {
    my $self = shift;
    my $v    = __PACKAGE__->viewer;
    $v->set_binding( \&HatedaEditor::Logic::Common::show_help, '?' );
    $v->set_binding( \&HatedaEditor::Logic::Viewer::edit,      'e' );
    $v->set_binding( \&HatedaEditor::Logic::Common::quit,      'q' );
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
