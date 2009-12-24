use strict;
use Test::More;

use File::Spec;
use Path::Class qw/file/;

BEGIN { use_ok 'Taroweb'; }

my $dir = File::Spec->tmpdir;
my $dovecot_passwd_file = file($dir, 'dovecot-passwd');
my $dfh = $dovecot_passwd_file->openw;
$dfh->print('hoge@vkgtaro.jp:{SSHA}AHJG/6ML0WKNz8SZ6x+rfKlq2H/CXj8Q');
$dfh->close;

my $postfix_virtual_file = file($dir, 'virtual');
my $pfh = $postfix_virtual_file->openw;
$pfh->print('vkgtaro@vkgtaro.jp vkgtaro.jp/vkgtaro/Maildir');
$pfh->close;

my $taroweb = Taroweb->new(
    dovecot_passwd_file  => $dovecot_passwd_file,
    postfix_virtual_file => $postfix_virtual_file,
    base_maildir => $dir,
);

$taroweb->add('komatsu@taro-web.com', 'p4ssw0rd');

ok $taroweb->commit();

my $dovecot_passwd = $dovecot_passwd_file->slurp;
like $dovecot_passwd, qr/^komatsu\@taro-web.com:{SSHA}/;

my $postfix_virtual = $postfix_virtual_file->slurp;
like $postfix_virtual, qr{komatsu\@taro-web.com taro-web.com/komatsu/Maildir};

my $expected_dir = $dir . q{/taro-web.com/komatsu/Maildir};
ok -e $expected_dir . q{/cur};
ok -e $expected_dir . q{/new};
ok -e $expected_dir . q{/tmp};

done_testing;
