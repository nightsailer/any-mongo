package AnyMongo::Compat;

use strict;
use warnings;
use AnyMongo;
*MongoDB:: = *AnyMongo::;
*MongoDB::Connection:: = *AnyMongo::Connection::;
*MongoDB::Database:: = *AnyMongo::Database::;
*MongoDB::Cursor:: = *AnyMongo::Cursor::;
*MongoDB::Collection:: = *AnyMongo::Collection::;
*MongoDB::BSON:: = *AnyMongo::BSON::;
*MongoDB::Code:: = *AnyMongo::BSON::Code;
*MongoDB::OID:: = *AnyMongo::BSON::OID::;
*MongoDB::Timestamp:: = *AnyMongo::BSON::Timestamp::;

1;
