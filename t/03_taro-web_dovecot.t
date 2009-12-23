use strict;
use Test::More;

use File::Spec;
use Path::Class qw/file/;

BEGIN { use_ok 'Taroweb::Dovecot'; }

my $dir = File::Spec->tmpdir;
my $passwd_file = file($dir, 'dovecot-passwd');
my $fh = $passwd_file->openw;
$fh->print('hoge@vkgtaro.jp:{SSHA}AHJG/6ML0WKNz8SZ6x+rfKlq2H/CXj8Q');
$fh->close;

my $dovecot = Taroweb::Dovecot->new(
    passwd_file => $passwd_file,
);

my $accounts = $dovecot->read_passwd_file();
is $accounts->{'vkgtaro.jp'}->{hoge}, '{SSHA}AHJG/6ML0WKNz8SZ6x+rfKlq2H/CXj8Q';

my $new_address = $dovecot->add('komatsu@taro-web.com', 'p4ssw0rd');
like $new_address, qr/^komatsu\@taro-web.com:{SSHA}/;

ok $dovecot->write_passwd_file();

my $content = $passwd_file->slurp;
like $content, qr/^komatsu\@taro-web.com:{SSHA}/;

done_testing;
