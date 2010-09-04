package AnyMongo;
# ABSTRACT: Asynchronous non-blocking MongoDB driver for AnyEvent applications
BEGIN {
  $AnyMongo::VERSION = '0.02';
}
use strict;
use warnings;
use XSLoader;
use AnyMongo::Connection;
sub new_connection {
    shift;
    return AnyMongo::Connection->new(@_);
}

XSLoader::load(__PACKAGE__, $AnyMongo::VERSION);
1;
__END__

=head1 MongoDB compatiblity


You can try L<AnyMongo::Compat>, this wrapper package try to make compatible
with MongoDB as possible.


=head1 INSTALLATION

See INSTALL.

=head1 SEE ALSO

You must check L<MongoDB>, because most code of L<AnyMongo> just stolen from it.