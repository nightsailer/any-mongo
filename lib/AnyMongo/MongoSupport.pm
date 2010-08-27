package AnyMongo::MongoSupport;
# ABSTRACT: Internal functions to support mongo wired protocol
use strict;
use warnings;
use AnyMongo;
use parent 'Exporter';
our @EXPORT_OK = qw(
    make_request_id
    build_get_more_message
    build_kill_cursor_message
    build_query_message
    build_insert_message
    build_remove_message
    build_update_message
    decode_bson_documents
);

# my $current_request_id = int(rand(1000000));
my $current_request_id = 0;

sub make_request_id { $current_request_id++ }


1;

__END__

=head1 Mongo Wire Protocol

There are two types of messages, client requests and database responses, each having a slightly different structure.

=head2 Client Request Messages

=head3 Standard Message Header

In general, each message consists of a standard message header followed by request-specific data.
The standard message header is structured as follows :

    struct MsgHeader {
        int32   messageLength; // total message size, including this
        int32   requestID;     // identifier for this message
        int32   responseTo;    // requestID from the original request
                               //   (used in reponses from db)
        int32   opCode;        // request type - see table below
    }

=head3 OP_UPDATE

struct OP_UPDATE {
    MsgHeader header;             // standard message header
    int32     ZERO;               // 0 - reserved for future use
    cstring   fullCollectionName; // "dbname.collectionname"
    int32     flags;              // bit vector. see below
    document  selector;           // the query to select the document
    document  update;             // specification of the update to perform
}

=head3 OP_INSERT

The OP_INSERT message is used to insert one or more documents into a collection.
The format of the OP_INSERT message is

    struct {
        MsgHeader header;             // standard message header
        int32     ZERO;               // 0 - reserved for future use
        cstring   fullCollectionName; // "dbname.collectionname"
        document* documents;          // one or more documents to insert into the collection
    }


=head3 OP_QUERY

The OP_QUERY message is used to query the database for documents in a collection.
The format of the OP_QUERY message is :

    struct OP_QUERY {
        MsgHeader header;                // standard message header
        int32     flags;                  // bit vector of query options.  See below for details.
        cstring   fullCollectionName;    // "dbname.collectionname"
        int32     numberToSkip;          // number of documents to skip
        int32     numberToReturn;        // number of documents to return
                                         //  in the first OP_REPLY batch
        document  query;                 // query object.  See below for details.
        [ document  returnFieldSelector; ] // Optional. Selector indicating the fields
                                         //  to return.  See below for details.
    }


=head3 OP_GETMORE

The OP_GETMORE message is used to query the database for documents in a collection.
The format of the OP_GETMORE message is :

    struct {
        MsgHeader header;             // standard message header
        int32     ZERO;               // 0 - reserved for future use
        cstring   fullCollectionName; // "dbname.collectionname"
        int32     numberToReturn;     // number of documents to return
        int64     cursorID;           // cursorID from the OP_REPLY
    }

=head3 OP_DELETE

The OP_DELETE message is used to remove one or more messages from a collection.
The format of the OP_DELETE message is :

    struct {
        MsgHeader header;             // standard message header
        int32     ZERO;               // 0 - reserved for future use
        cstring   fullCollectionName; // "dbname.collectionname"
        int32     flags;              // bit vector - see below for details.
        document  selector;           // query object.  See below for details.
    }

=head3 OP_KILL_CURSORS

The OP_KILL_CURSORS message is used to close an active cursor in the database. This is necessary to ensure
that database resources are reclaimed at the end of the query. The format of the OP_KILL_CURSORS message is :

struct {
    MsgHeader header;            // standard message header
    int32     ZERO;              // 0 - reserved for future use
    int32     numberOfCursorIDs; // number of cursorIDs in message
    int64*    cursorIDs;         // sequence of cursorIDs to close
}



=head2 Database Response Messages

=head3 OP_REPLY

The OP_REPLY message is sent by the database in response to an
L<MongoDB::MongoSupport/OP_QUERY>  or L<MongoDB::MongoSupport/OP_GET_MORE>
message. The format of an OP_REPLY message is:

    struct {
        MsgHeader header;         // standard message header
        int32     responseFlags;  // bit vector - see details below
        int64     cursorID;       // cursor id if client needs to do get more's
        int32     startingFrom;   // where in the cursor this reply is starting
        int32     numberReturned; // number of documents in the reply
        document* documents;      // documents
    }
