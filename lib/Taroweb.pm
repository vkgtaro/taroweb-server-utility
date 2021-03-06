package Taroweb;

use Mouse;
use utf8;
our $VERSION = '0.01';

use Taroweb::Postfix;
use Taroweb::Dovecot;

has dovecot_passwd_file => (
    is => 'rw',
);

has postfix_virtual_file => (
    is => 'rw',
);

has base_maildir => (
    is => 'rw',
);

has postfix => (
    is => 'ro',
    lazy_build => 1,
);

has dovecot => (
    is => 'ro',
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

no Mouse;

sub _build_postfix {
    my ( $self ) = @_;
    my $postfix = Taroweb::Postfix->new(
        virtual => $self->postfix_virtual_file,
        base_maildir => $self->base_maildir
    );
    $postfix->read_virtual_file();

    return $postfix;
}

sub _build_dovecot {
    my ( $self ) = @_;
    my $dovecot = Taroweb::Dovecot->new( passwd_file => $self->dovecot_passwd_file );
    $dovecot->read_passwd_file();

    return $dovecot;
}

sub add {
    my ($self, $address, $password) = @_;

    $self->dovecot->add($address, $password);
    $self->postfix->add($address);
}

sub commit {
    my ( $self ) = @_;

    $self->postfix->make_maildirs();
    $self->postfix->write_virtual_file();
    $self->dovecot->write_passwd_file();
}

__PACKAGE__;

__END__

=encoding utf8

=head1 NAME

Taroweb - taro-web.com サーバユーティリティ

=head1 SYNOPSIS

  use Taroweb;

=head1 DESCRIPTION

taro-web.com で何か作りたくなった時の名前空間どうするんだ的な

=head1 AUTHOR

Daisuke Komatsu E<lt>vkg.taro@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
