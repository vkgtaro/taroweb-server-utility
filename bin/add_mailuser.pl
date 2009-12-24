use strict;
use warnings;
use utf8;

package Taroweb::AddMailUser;
use Mouse;
with 'MouseX::Getopt';

use Taroweb;
use YAML::Syck;

has c => (
    is => 'rw',
    isa => 'Str',
);

has mail => (
    is => 'rw',
    isa => 'Str',
);

has password => (
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
    
    $taroweb->add( $self->mail, $self->password);
    $taroweb->commit();
}

__PACKAGE__->meta->make_immutable;
no Mouse;

package main;

Taroweb::AddMailUser->new_with_options->run;

__END__
