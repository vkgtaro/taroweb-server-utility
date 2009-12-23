use inc::Module::Install;
name 'Taroweb';
all_from 'lib/Taroweb.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
