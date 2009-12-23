use strict;
use warnings;
use utf8;

use lib qw(lib);
use Path::Class;

use Taroweb::Maildir;
use YAML::Syck;

my $config = {
    maildir => '/Users/vkgtaro/Documents/works'
};

my $maildir = Taroweb::Maildir->new(
    base_dir => $config->{maildir},
    domain   => 'taro-web.com',
);

$maildir->make_maildir('komatsu');

