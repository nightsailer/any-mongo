package AnyMongo::BSON::Timestamp;
# ABSTRACT: BSON Timestamps data type, it is used internally by MongoDB's replication.
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


# __PACKAGE__->meta->make_immutable (inline_destructor => 0);
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

AnyMongo::Timstamp 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

