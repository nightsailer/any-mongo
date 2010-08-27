package AnyMongo::BSON;

use strict;
use warnings;
use AnyMongo;
use parent 'Exporter';
our @EXPORT_OK = qw(bson_encode bson_decode);

$AnyMongo::BSON::char = '$';
$AnyMongo::BSON::utf8_flag_on = '$';

=head2 Return boolean values as booleans instead of integers

    $MongoDB::BSON::use_boolean = 1

By default, booleans are deserialized as integers.  If you would like them to be
deserialized as L<boolean/true> and L<boolean/false>, set 
C<$MongoDB::BSON::use_boolean> to 1.

=cut

$AnyMongo::BSON::use_boolean = 0;

1;
__END__


=head1 NAME

AnyMongo::BSON 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

