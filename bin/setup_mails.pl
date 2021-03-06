use strict;
use warnings;
use utf8;

package Taroweb::SetupMails;
use Mouse;
with 'MouseX::Getopt';

use Taroweb;
use YAML::Syck;

has c => (
    is => 'rw',
    isa => 'Str',
);

sub run {
    my ($self) = @_;

    my $config = LoadFile( $self->c || 'config/config.yaml' );
    
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
}

__PACKAGE__->meta->make_immutable;
no Mouse;

package main;

Taroweb::SetupMails->new_with_options->run;

__END__
