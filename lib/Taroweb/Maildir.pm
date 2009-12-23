package Taroweb::Maildir;

use Mouse;
use Mouse::Util::TypeConstraints;
use Path::Class;

subtype 'Dir'
    => as 'Object'
    => where { $_->isa('Path::Class::Dir') };

has base_dir => (
    is => 'rw',
    isa => 'Dir',
    coerce => 1,
);

has domain => (
    is => 'rw',
    isa => 'Str',
);

coerce 'Dir'
    => from 'Str'
    => via { dir($_) };

__PACKAGE__->meta->make_immutable;

no Mouse;

sub make_maildir {
    my ($self, $account) = @_;

    my $base_dir = $self->base_dir;
    my $maildir = dir( $base_dir, $self->domain, $account, 'Maildir');

    foreach my $subdir ( qw/ cur tmp new / ) {
        my $dir = $maildir->subdir($subdir);
        eval {
            $dir->mkpath(755);
        };
        if ($@) {
            die sprintf "can not create maildir for %s@%s: %s", $account, $self->domain, $@;
        }
    }

    return 1;
}

__PACKAGE__;

__END__

=encoding utf8

=head1 NAME

Taroweb -

=head1 SYNOPSIS

  use Taroweb;

=head1 DESCRIPTION

Taroweb is

=head1 AUTHOR

Daisuke Komatsu E<lt>vkg.taro@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut