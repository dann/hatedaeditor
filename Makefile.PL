use inc::Module::Install;
name 'HatedaEditor';
all_from 'lib/HatedaEditor.pm';

requires $_
    for (
    qw/
    Curses::UI
    File::HomeDir
    FindBin::libs
    Moose
    MooseX::ClassAttribute
    MooseX::Singleton
    Path::Class
    WWW::HatenaDiary
    YAML
    HTTP::Cookies
    /
    );

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
