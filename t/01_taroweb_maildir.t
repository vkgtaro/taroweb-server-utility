use strict;
use Test::More;

use File::Spec;

BEGIN { use_ok 'Taroweb::Maildir'; }

my $dir = File::Spec->tmpdir;

my $maildir = Taroweb::Maildir->new(
    base_dir => $dir,
    domain   => 'taro-web.com',
);

my $new_maildir = $maildir->make_maildir('komatsu');

my $expected_dir = $dir . q{/taro-web.com/komatsu/Maildir};
diag $expected_dir;

is $new_maildir, $expected_dir;
ok -e $expected_dir . q{/cur};
ok -e $expected_dir . q{/new};
ok -e $expected_dir . q{/tmp};

done_testing;

