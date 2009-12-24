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
    base_maildir => "$dir",
    virtual => $virtual_file,
);

ok $postfix->lock();
my $accounts = $postfix->read_virtual_file();
is $accounts->{'vkgtaro.jp'}->{vkgtaro}, 'vkgtaro.jp/vkgtaro/Maildir';

my $new_address = $postfix->add('komatsu@taro-web.com');
is $new_address, 'komatsu@taro-web.com taro-web.com/komatsu/Maildir';

ok $postfix->make_maildirs();
ok $postfix->write_virtual_file();
ok $postfix->unlock();

my $content = $virtual_file->slurp;
like $content, qr{komatsu\@taro-web.com taro-web.com/komatsu/Maildir};

my $expected_dir = $dir . q{/taro-web.com/komatsu/Maildir};
ok -e $expected_dir . q{/cur} && rmdir $expected_dir . q{/cur};
ok -e $expected_dir . q{/new} && rmdir $expected_dir . q{/new};
ok -e $expected_dir . q{/tmp} && rmdir $expected_dir . q{/tmp};

done_testing;
