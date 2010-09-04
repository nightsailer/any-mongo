package AnyMongo::Compat;
# ABSTRACT: Make better compatible with L<MongoDB>.
use strict;
use warnings;
use AnyMongo;

sub make_fake_isa {
    my($fake_class) = @_;
    return sub {
        my ($self,$class) = @_;
        return 1 if $class eq $fake_class;
        return $self->SUPER::isa($class);
    };
}


*MongoDB::BSON::char = *AnyMongo::BSON::char;
*MongoDB::BSON::use_boolean = *AnyMongo::BSON::use_boolean;
*MongoDB::BSON::utf8_flag_on = *AnyMongo::BSON::utf8_flag_on;

# fake these isa
*AnyMongo::Database::isa = make_fake_isa('MongoDB::Database');
*AnyMongo::Collection::isa = make_fake_isa('MongoDB::Collection');
*AnyMongo::Cursor::isa = make_fake_isa('MongoDB::Cursor');
*AnyMongo::BSON::Timestamp::isa = make_fake_isa('MongoDB::Timestamp');
*AnyMongo::BSON::OID::isa = make_fake_isa('MongoDB::OID');
*AnyMongo::BSON::Code::isa = make_fake_isa('MongoDB::Code');
*AnyMongo::BSON::MaxKey::isa = make_fake_isa('MongoDB::MaxKey');
*AnyMongo::BSON::MinKey::isa = make_fake_isa('MongoDB::MinKey');

package MongoDB;
use parent 'AnyMongo';

package MongoDB::Database;
use parent 'AnyMongo::Database';

package MongoDB::Connection;
use parent 'AnyMongo::Connection';

package MongoDB::Cursor;
use parent 'AnyMongo::Cursor';

package MongoDB::Collection;
use parent 'AnyMongo::Collection';

package MongoDB::BSON;
use parent 'AnyMongo::BSON';

package MongoDB::Code;
use parent 'AnyMongo::BSON::Code';

package MongoDB::OID;
use parent 'AnyMongo::BSON::OID';
package MongoDB::Timestamp;
use parent 'AnyMongo::BSON::Timestamp';
1;