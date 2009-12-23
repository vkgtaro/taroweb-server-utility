use inc::Module::Install;
name 'Taroweb';
all_from 'lib/Taroweb.pm';

requires 'Mouse';
requires 'Path::Class';
requires 'Mouse::Util::TypeConstraints';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'File::Spec';
use_test_base;
auto_include;
WriteAll;
