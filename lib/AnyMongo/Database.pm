package AnyMongoDB::Database;
# ABSTRACT: Asynchronous MongoDB::Database
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;
extends qw(MongoDB::Database);



sub test_ok {
    confess 'test_ok';
}

__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 NAME

MongoDB::AnyEvent::Database 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

