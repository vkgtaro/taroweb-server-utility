use strict;
use Test::More;

use File::Spec;
use Path::Class qw/file/;

BEGIN { use_ok 'Taroweb::Postfix'; }

my $dir = File::Spec->tmpdir;
my $virtual_file = file($dir, 'virtual');
my $fh = $virtual_file->openw;
$fh->print('vkgtaro@vkgtaro.jp vkgtaro.jp/vkgtaro/Maildir');
$fh->close;

my $postfix = Taroweb::Postfix->new(
    virtual => $virtual_file,
);

my $accounts = $postfix->read_virtual_file();
is $accounts->{'vkgtaro.jp'}->{vkgtaro}, 'vkgtaro.jp/vkgtaro/Maildir';

my $new_address = $postfix->add('komatsu@taro-web.com');
is $new_address, 'komatsu@taro-web.com taro-web.com/komatsu/Maildir';

ok $postfix->write_virtual_file();

my $content = $virtual_file->slurp;
like $content, qr{komatsu\@taro-web.com taro-web.com/komatsu/Maildir};

done_testing;
