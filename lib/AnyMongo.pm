package AnyMongo;
# ABSTRACT: Asynchronous non-blocking MongoDB driver for AnyEvent applications
BEGIN {
  $AnyMongo::VERSION = '0.03';
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

=head1 SYNOPSIS

    use AnyMongo;

    my $connection = AnyMongo::new_connection(host => 'mongodb://localhost:27017');
    my $database   = $connection->get_database('foo');
    my $collection = $database->get_collection('bar');
    my $id         = $collection->insert({ some => 'data' });
    my $data       = $collection->find_one({ _id => $id });

    # AnyMongo also can run in official MongoDB compatible mode,
    # Then you can run your old code depends on mongoDB quickly
    use AnyMongo::Compat;
    # now AnyMongo will mock most MongoDB package
    my $con = MongoDB::Connection->new(host => 'mongodb://localhost');
    my $db = $con->get_database('foo');


=head1 MongoDB compatiblity


You can try L<AnyMongo::Compat>, this wrapper package try to make compatible
with MongoDB as possible.


=head1 INSTALLATION

See INSTALL.

=head1 SEE ALSO

You must check L<MongoDB>, because most code of L<AnyMongo> just stolen from it.