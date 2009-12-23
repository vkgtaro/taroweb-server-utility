package Taroweb::Dovecot;

use Mouse;
use Mouse::Util::TypeConstraints;
use Crypt::SaltedHash;
use DateTime;
use Email::Valid;
use File::Copy;
use Fcntl qw(:flock);
use Path::Class;

subtype 'File'
    => as 'Object'
    => where { $_->isa('Path::Class::File') };

has passwd_file => (
    is => 'rw',
    isa => 'File',
    coerce => 1,
);

has accounts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has comments => (
    is => 'rw',
    isa => 'Str',
);

coerce 'File'
    => from 'Str'
    => via { file($_) };

__PACKAGE__->meta->make_immutable;

no Mouse;

sub read_passwd_file {
    my ($self) = @_;

    my $fh = $self->passwd_file->openr
        or die 'can not open '.  $self->passwd_file . q{:} . $!;

    my $comments = '';
    while ( my $line = <$fh> ) {
        if ( $line =~ /^#/ ) {
            $comments .= $line;
            next;
        }

        my ($account, $domain, $hashed_password) = $self->parse_line_from_passwd_file($line);
        $self->accounts->{$domain}->{$account} = $hashed_password;
    }

    $self->comments( $comments );

    return $self->accounts;
}

sub parse_line_from_passwd_file {
    my ( $self, $line ) = @_;

    if ( $line =~ m{\A (.+) @ (.+) : (.+) \z}xms ) {
        my $account = $1;
        my $domain = $2;
        my $hashed_password = $3;

        return ($account, $domain, $hashed_password);
    }

    return;
}

sub add {
    my ( $self, $address, $password ) = @_;

    die $address . ' is not mail address.'
        unless Email::Valid->address($address);

    if ( $address =~ m{\A (.+) @ (.+) \z}xms ) {
        my $account = $1;
        my $domain  = $2;

        my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1');
        $csh->add('hoge');
        my $hashed_password = $csh->generate;
        $self->accounts->{$domain}->{$account} = $hashed_password;

        return $self->build_line($account, $domain, $hashed_password);
    }

    return;
}

sub build_line {
    my ( $self, $account, $domain, $hashed_password ) = @_;

    return sprintf "%s@%s:{SSHA}%s", $account, $domain, $hashed_password;
}

sub write_passwd_file {
    my ( $self ) = @_;

    if ( -f $self->passwd_file ) {
        my $to_file = sprintf "%s.%s.bak", $self->passwd_file, DateTime->now->strftime('%Y.%m.%d.%H.%M.%S');
        copy $self->passwd_file, $to_file
            or die $!;
    }
    else {
        $self->passwd_file->touch
            or die $!;
    }

    my $fh = $self->passwd_file->openw
        or die 'can not open '.  $self->passwd_file . q{:} . $!;
    flock($fh, LOCK_EX);

    my $contents = $self->as_string;
    $fh->print($contents);
    $fh->print($self->comments);

    flock($fh, LOCK_UN);
    return $fh->close;
}

sub as_string {
    my ( $self ) = @_;

    my $accounts = $self->accounts;

    my $string = '';
    foreach my $domain ( keys %{$accounts} ) {
        foreach my $account ( keys %{$accounts->{$domain}} ) {
            $string .= $self->build_line($account, $domain, $accounts->{$domain}->{$account}) . "\n";
        }
    }

    return $string;
}

__PACKAGE__;

__END__

=encoding utf8

=head1 NAME

Taroweb::Dovecot - Dovecot でアカウント追加したりとか

=head1 SYNOPSIS

  use Taroweb::Dovecot;

=head1 DESCRIPTION

dovecot の passwd ファイルに追加したりとか

=head1 METHODS

=head2 add

アカウント追加

=head2 read_passwd_file

passwd ファイルを読み込み

=head2 write_passwd_file

passwd ファイルに追記

=head1 AUTHOR

Daisuke Komatsu E<lt>vkg.taro@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
