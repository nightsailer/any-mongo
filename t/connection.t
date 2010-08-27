use strict;
use warnings;
use Test::More tests => 1;
use Data::Dumper;
use AnyEvent;
use AnyMongo;

my $con = AnyMongo->new_connection(host => 'mongodb://127.0.0.1' ,auto_connect => 0);
# print Dumper($con);
print "=========RECV=======\n";
# my $cv = AE::cv;
# $con->connect( cb => sub { print "Hello,I'm callback.\n" },cv => $cv );
$con->connect( cb => sub { print "Hello,I'm callback.\n" })->recv;


my $db = $con->get_database('test');
my $col = $db->get_collection('anymongo');

my $id = $col->insert({ name => 'mongo','test' => 5 });

print $col->count();
