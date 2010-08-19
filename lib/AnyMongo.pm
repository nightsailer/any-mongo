package AnyMongo;
# ABSTRACT: Asynchronous non-blocking MongoDB driver for AnyEvent applications
use strict;
use warnings;
use AnyMongo::Connection;

sub new_connection {
    shift;
    return AnyMongo::Connection->new(@_);
}

1;
__END__