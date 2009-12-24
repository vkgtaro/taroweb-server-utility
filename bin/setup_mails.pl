use strict;
use warnings;
use utf8;

use Taroweb;
use YAML::Syck;

my $config = LoadFile('config/config.yaml');

my $taroweb = Taroweb->new(
    dovecot_passwd_file  => $config->{dovecot_passwd},
    postfix_virtual_file => $config->{postfix_virtual},
    base_maildir         => $config->{base_maildir},
);

foreach my $domain ( keys %{$config->{mails}} ) {
    foreach my $account ( keys %{$config->{mails}->{$domain}} ) {
        $taroweb->add( $account . q{@} . $domain, $config->{mails}->{$domain}->{$account});
    }
}

$taroweb->commit();

