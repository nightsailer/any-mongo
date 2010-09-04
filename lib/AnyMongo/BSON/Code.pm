package AnyMongo::BSON::Code;
# ABSTRACT: BSON type,it's used to represent JavaScript code and, optionally, scope.
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;

=head1 ATTRIBUTES

=head2 code

A string of JavaScript code.

=cut

has code => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 scope

An optional hash of variables to pass as the scope.

=cut

has scope => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

# __PACKAGE__->meta->make_immutable (inline_destructor => 0);
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

AnyMongo::Code 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

