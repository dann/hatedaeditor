use Test::Dependencies
	exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic HatedaEditor/],
	style   => 'light';
ok_dependencies();
