use inc::Module::Install;
name 'HatedaEditor';
all_from 'lib/HatedaEditor.pm';

requires $_ for (qw/ /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
