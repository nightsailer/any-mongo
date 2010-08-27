package AnyMongo::BSON::Timestamp;

use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;

=head1 ATTRIBUTES

=head2 sec

Seconds since epoch.

=cut

has sec => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=head2 inc

Incrementing field.

=cut

has inc => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


__PACKAGE__->meta->make_immutable (inline_destructor => 0);
1;
__END__


=head1 NAME

AnyMongo::Timstamp 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT
