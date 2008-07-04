package HatedaEditor::ConfigLoader;
use strict;
use YAML;
use File::HomeDir;
use Path::Class qw(file);
use ExtUtils::MakeMaker ();
use MooseX::Singleton;

has 'changed' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'conf' => (
    is      => 'rw',
    default => sub { file( File::HomeDir->my_home, ".hdedit" ) },
);

no Moose;

sub prompt {
    my ( $self, $prompt ) = @_;
    my $value = ExtUtils::MakeMaker::prompt($prompt);
    $self->changed( $self->changed + 1 );
    return $value;
}

sub load {
    my $self = shift;
    my $config = eval { YAML::LoadFile( $self->conf ) } || {};
    $config->{username} ||= $self->prompt("user name:");
    $config->{password}
        ||= $self->prompt("password:");
    $config->{group_list}
        ||= $self->prompt("group (space separated ):");
    $config->{default_group} ||= 'NONE';
    $self->save($config);
    return $config;
}

sub update {
    my ($self, $key, $value) = @_;
    my $config = eval { YAML::LoadFile( $self->conf ) } || {};
    $config->{$key} = $value;
    $self->changed( $self->changed + 1 );
    $self->save($config);
}

sub save {
    my ( $self, $conf ) = @_;
    if($self->changed) {
        YAML::DumpFile( $self->conf, $conf );
        chmod 0600, $self->conf;
    }
    $self->changed(0);
}

__PACKAGE__->meta->make_immutable;

1;
