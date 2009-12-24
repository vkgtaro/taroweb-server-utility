package Taroweb::Postfix;

use Mouse;
use Mouse::Util::TypeConstraints;
use utf8;

use DateTime;
use Email::Valid;
use File::Copy;
use Fcntl qw(:flock);
use Path::Class;

subtype 'PostfixFile'
    => as 'Object'
    => where { $_->isa('Path::Class::File') };

subtype 'PostfixLock'
    => as 'Object'
    => where { $_->isa('IO::File') };

subtype 'MailDir'
    => as 'Object'
    => where { $_->isa('Path::Class::Dir') };

has base_maildir => (
    is => 'rw',
    isa => 'MailDir',
    coerce => 1,
    default => '/ebs/vmail',
);

has lock_file => (
    is => 'ro',
    isa => 'PostfixLock',
    coerce => 1,
    default => 'postfix_lock',
);

has virtual => (
    is => 'rw',
    isa => 'PostfixFile',
    coerce => 1,
);

has accounts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has new_accounts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has comments => (
    is => 'rw',
    isa => 'Str',
);

coerce 'PostfixFile'
    => from 'Str'
    => via { file($_) };

coerce 'PostfixLock'
    => from 'Str'
    => via { my $lock = file($_); $lock->openw; };

coerce 'MailDir'
    => from 'Str'
    => via { dir($_) };

__PACKAGE__->meta->make_immutable;

no Mouse;

sub read_virtual_file {
    my ($self) = @_;

    my $fh = $self->virtual->openr
        or die 'can not open '.  $self->virtual;

    my $comments = '';
    while ( my $line = <$fh> ) {
        if ( $line =~ /^#/ ) {
            $comments .= $line;
            next;
        }

        my ($account, $domain, $dir) = $self->parse_line_from_virtual_file($line);
        $self->accounts->{$domain}->{$account} = $dir;
    }

    $self->comments( $comments );

    return $self->accounts;
}

sub parse_line_from_virtual_file {
    my ( $self, $line ) = @_;

    if ( $line =~ m{\A (.+) @ (.+) \s+ (.+) \z}xms ) {
        my $account = $1;
        my $domain = $2;
        my $dir = $3;

        return ($account, $domain, $dir);
    }

    return;
}

sub add {
    my ( $self, $address ) = @_;

    die $address . ' is not mail address.'
        unless Email::Valid->address($address);

    if ( $address =~ m{\A (.+) @ (.+) \z}xms ) {
        my $account = $1;
        my $domain  = $2;

        $self->accounts->{$domain}->{$account} = $self->build_maildir($account, $domain);
        $self->new_accounts->{$domain}->{$account} = $self->build_maildir($account, $domain);

        return $self->build_line($account, $domain);
    }

    return;
}

sub build_line {
    my ( $self, $account, $domain ) = @_;

    return sprintf "%s@%s %s", $account, $domain, $self->build_maildir($account, $domain);
}

sub build_maildir {
    my ( $self, $account, $domain ) = @_;

    return sprintf "%s/%s/Maildir", $domain, $account;
}

sub write_virtual_file {
    my ( $self ) = @_;

    if ( -f $self->virtual ) {
        my $to_file = sprintf "%s.%s.bak", $self->virtual, DateTime->now->strftime('%Y.%m.%d.%H.%M.%S');
        copy $self->virtual, $to_file
            or die $!;
    }
    else {
        $self->virtual->touch
            or die $!;
    }

    my $fh = $self->virtual->openw
        or die 'can not open '.  $self->virtual . q{:} . $!;
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
            $string .= $self->build_line($account, $domain) . "\n";
        }
    }

    return $string;
}

sub make_maildirs {
    my ( $self ) = @_;

    my $accounts = $self->new_accounts;

    my $string = '';
    foreach my $domain ( keys %{$accounts} ) {
        foreach my $account ( keys %{$accounts->{$domain}} ) {
            $self->make_maildir($account, $domain);
        }
    }

    return 1;
}

sub make_maildir {
    my ($self, $account, $domain) = @_;

    my $base_dir = $self->base_maildir;
    my $maildir = dir( $base_dir, $domain, $account, 'Maildir');
    
    foreach my $subdir ( qw/ cur tmp new / ) {
        my $dir = $maildir->subdir($subdir);
        $dir->mkpath(755);
    }

    return $maildir;
}

sub lock {
    my ( $self ) = @_;
    flock($self->lock_file, LOCK_EX);
}

sub unlock {
    my ( $self ) = @_;
    flock($self->lock_file, LOCK_UN);
}


__PACKAGE__;

__END__

=encoding utf8

=head1 NAME

Taroweb::Postfix - Postfix でメールアドレス追加したりとか

=head1 SYNOPSIS

  use Taroweb::Postfix;

=head1 DESCRIPTION

postfix の virtual file に追加したりとか

=head1 METHODS

=head2 add

アカウント追加

=head2 read_virtual_file

virtual ファイルを読み込み

=head2 write_virtual_file

virtual ファイルに追記

=head1 AUTHOR

Daisuke Komatsu E<lt>vkg.taro@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
