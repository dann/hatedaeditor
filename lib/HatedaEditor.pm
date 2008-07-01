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
use Encode;

our $VERSION = '0.01';

class_has 'win'    => ( is => 'rw', );
class_has 'viewer' => ( is => 'rw', );
class_has 'cui'    => (
    is      => 'rw',
    default => sub {
        return Curses::UI->new( -color_support => 1 );
    }
);
class_has 'api' => ( is => 'rw', );

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

    # focusするタイミングを調べる
    __PACKAGE__->viewer->focus();
    __PACKAGE__->cui->leave_curses;
}

sub _setup_cui {
    my $self = shift;
    $self->_setup_cui_binding;
}

sub _setup_cui_binding {
    __PACKAGE__->cui->set_binding( \&HatedaEditor::Logic::Common::quit,
        "\cq" );
    __PACKAGE__->cui->set_binding( \&HatedaEditor::Logic::Common::quit,
        "\cc" );
}

sub _setup_menu {
    my $self = shift;
    my @menu = (
        {   -label => 'File',
            -submenu =>
                [ { -label => 'Exit      ^Q', -value => \&exit_dialog } ]
        },
    );
    my $menu = __PACKAGE__->cui->add(
        'menu', 'Menubar',
        -menu => \@menu,
        -fg   => "blue",
    );
}

# refactor
sub exit_dialog() {
    my $return = __PACKAGE__->cui->dialog(
        -message => "Do you really want to quit?",
        -title   => "Are you sure???",
        -buttons => [ 'yes', 'no' ],
    );

    exit(0) if $return;
}

sub _setup_window {
    my $self = shift;
    $self->win(
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
        $self->win->add(
            "text", "TextViewer",
            -text => "Hatena Diary Editor! Show help with '?';\n",
        )
    );

    $self->_setup_viewer_binding;
}

sub _setup_viewer_binding {
    my $self = shift;
    __PACKAGE__->viewer->set_binding(
        \&HatedaEditor::Logic::Common::show_help, '?' );
    __PACKAGE__->viewer->set_binding( \&HatedaEditor::Logic::Viewer::edit,
        'e' );
    __PACKAGE__->viewer->set_binding( \&HatedaEditor::Logic::Common::quit,
        'q' );
    __PACKAGE__->viewer->set_binding( sub { __PACKAGE__->viewer->focus; },
        'v' );
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
