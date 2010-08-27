package AnyMongo;
# ABSTRACT: Asynchronous non-blocking MongoDB driver for AnyEvent applications
use strict;
use warnings;
use XSLoader;
our $VERSION = '0.01';
use AnyMongo::Connection;
sub new_connection {
    shift;
    return AnyMongo::Connection->new(@_);
}

XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__