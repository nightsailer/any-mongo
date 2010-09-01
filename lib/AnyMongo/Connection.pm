package AnyMongo::Connection;
# ABSTRACT: Asynchronous MongoDB::Connection
use strict;
use warnings;
use constant {
    DEBUG => $ENV{ANYMONGO_DEBUG},
    # bson type
    BSON_INT32 => 4,
    BSON_INT64 => 8,
    # msg header size
    STANDARD_HEADER_SIZE => 16,
    RESPONSE_HEADER_SIZE => 20,
    # opcode
    OP_REPLY    => 1,
    OP_MSG      => 1000, #generic msg command followed by a string
    OP_UPDATE	=> 2001, #update document
    OP_INSERT	=> 2002, #insert new document
    RESERVED	=> 2003, #formerly used for OP_GET_BY_OID
    OP_QUERY	=> 2004, #query a collection
    OP_GET_MORE	=> 2005, #Get more data from a query. See Cursors
    OP_DELETE	=> 2006, #Delete documents
    OP_KILL_CURSORS  => 2007,
    # flags
    REPLY_CURSOR_NOT_FOUND     => 1, 
    REPLY_QUERY_FAILURE        => 2,
    REPLY_SHARD_CONFIG_STALE   => 4,
    REPLY_AWAIT_CAPABLE        => 8,
    
};

use Carp qw(croak);
use Data::Dumper;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyMongo::BSON qw(bson_decode);
use AnyMongo::MongoSupport qw(decode_bson_documents);
use AnyMongo::Cursor;
use namespace::autoclean;
use Any::Moose;

has master_handler => (
    isa => 'Maybe[AnyEvent::Handle]',
    is  => 'rw',
    clearer  => 'clear_master_handler',
);

has ts => (
    is      => 'rw',
    isa     => 'Int',
    default => 0
);

has db_name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'admin',
);

has query_timeout => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    default  => sub { return $AnyMongo::Cursor::timeout; },
);

has auto_connect => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has auto_reconnect => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'mongodb://localhost:27017',
);

has w => (
    is      => 'rw',
    isa     => 'Int',
    default => 1,
);


has wtimeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 1000,
);

has timeout => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 20000,
);

has username => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has password => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

# 
# has _servers => (
#     is => 'rw',
#     isa => 'HashRef',
#     required => 0,
#     clearer => 'clear_mongo_servers',
#     default => sub { {} },
# );

sub CLONE_SKIP { 1 }

sub BUILD { shift->_init }

sub _init {
    my ($self) = @_;
    eval "use ${_}" # no Any::Moose::load_class becase the namespaces already have symbols from the xs bootstrap
        for qw/AnyMongo::Database AnyMongo::Cursor AnyMongo::BSON::OID/;
    $self->_parse_servers();
    if ($self->auto_connect) {
        $self->connect->recv;
        # if (defined $self->username && defined $self->password) {
        #     $self->authenticate($self->db_name, $self->username, $self->password);
        # }
    }
    
}

sub connect {
    my ($self,%args) = @_;
    my ($cb,$cv) = @args{'cb','cv'};

    return if $self->{_is_connected};

    $self->{_connected_server_count} = 0;
    $self->{_is_connected} = 0;
    
    $args{cv}->begin if $args{cv};
    
    my $connect_cv = AE::cv {
        if (! $self->{_connected_server_count} ) {
            delete $self->{mongo_servers};
            croak "Failed to connect to any mongodb servers";
        }
        $self->{_is_connected} = 1;
        $args{cb}->($self) if $args{cb};
        $args{cv}->end if $args{cv};
        $self->check_master;
    };
    foreach my $k ( keys %{ $self->{mongo_servers} } ) {
        $self->_connect_one($k, $connect_cv);
    }
    $connect_cv;
}


sub _connect_one {
    my ($self, $server_key, $cv) = @_;
    
    my $mongo_servers = $self->{mongo_servers};
    
    return if $mongo_servers->{$server_key}->{guard};
    
    my ($host,$port) = @{$mongo_servers->{$server_key}}{'host','port'};
    $cv->begin if $cv;
    
    # warn "connect to $server_key" if DEBUG;
    
    my $server = $mongo_servers->{$server_key};
    $server->{guard} = tcp_connect $host,$port, sub {
        my ($fh, $host, $port) = @_;
        if (!$fh) {
            warn "failed to connect to $server_key\n" if DEBUG;
            delete $server->{guard};
        }
        else {
            my $h; $h = AnyEvent::Handle->new(
                fh => $fh,
                on_eof => sub {
                    my $h = delete $server->{handler};
                    $h->destroy();
                    undef $h;
                    delete $server->{guard};
                },
                on_error => sub {
                    my ($hdl, $fatal, $msg) = @_;
                    warn "got error $msg\n" if DEBUG; 
                    my $h = delete $server->{handler};
                    $h->destroy();
                    delete $server->{guard};
                    $self->_connect_one($server_key) if $self->{auto_reconnect};
                    undef $h;
                },
            );
            @{ $server }{'handler','connected'} = ($h,1);
            $self->{master_id} = $server_key;
            $self->{_connected_server_count}++;
            DEBUG and warn "$server_key connected ok";
        }
        $cv->end if $cv;
    };
    
}


sub _parse_servers {
    my ($self) = @_;
    my $str = $self->host;
    $str = substr $self->host, 10 if $str =~ /^mongodb:\/\//;
    my @pairs = split ",", $str;
    my $servers = {};
    for my $h (@pairs) {
        my ($host,$port) = split ':',$h;
        $port ||= 27017;
        $servers->{$host.':'.$port} = {
            connected => 0,
            handler => undef,
            host => $host,
            port => $port,
        };
    }
    # $self->_servers($servers);
    $self->{mongo_servers} = $servers;
}

sub check_master {
    my ($self) = @_;
    return unless $self->{master_id};
    my $mongo_servers = $self->{mongo_servers};
    my $master_id = $self->{master_id};
    $self->master_handler($mongo_servers->{$master_id}->{handler});
    # todo: real find master work
}

sub send_message {
    my ($self,$data) = @_;
    my $hd = $self->master_handler;
    $hd->push_write($data);
}

sub recv_message {
    my ($self) = @_;
    my $hd = $self->master_handler;
    my ($message_length,$request_id,$response_to,$op) = $self->_receive_header;
    warn "length:$message_length request_id:$request_id response_to:$response_to op:$op\n" if DEBUG;
    my ($response_flags,$cursor_id,$starting_from,$number_returned) = $self->_receive_response_header();
    warn "response_flags:$response_flags cursor_id:$cursor_id starting_from:$starting_from number_returned:$number_returned\n" if DEBUG;
    $self->_check_respone_flags($response_flags);
    my $results =  $self->_read_documents($message_length-36,$cursor_id);
    # my $results =  $self->_read_documents($number_returned,$cursor_id);
    return ($number_returned,$cursor_id,$results);
}

sub _check_respone_flags {
    my ($self,$flags) = @_;
    if (($flags & REPLY_CURSOR_NOT_FOUND) != 0) {
        croak("cursor not found");
    }
}

sub receive_data {
    my ($self,$size) = @_;
    my $hd = $self->master_handler;
    my $cv = AE::cv;
    $hd->push_read(chunk => $size, sub {
        my ($hdl, $bytes) = @_;
        $cv->send($_[1]);
    });
    $cv->recv;
}


sub _receive_header {
    my ($self,$cursor) = @_;
    my $header_buf = $self->receive_data(STANDARD_HEADER_SIZE);
    croak 'Short read for DB response header; length:'.length($header_buf) unless length $header_buf == STANDARD_HEADER_SIZE;
    return unpack('V4',$header_buf);
}

sub _receive_response_header {
    my ($self) = @_;
    my $header_buf = $self->receive_data(RESPONSE_HEADER_SIZE);
    croak 'Short read for DB response header' unless length $header_buf == RESPONSE_HEADER_SIZE;
    my ($response_flags) = unpack 'V',substr($header_buf,0,BSON_INT32);
    my ($cursor_id) = unpack 'j',substr($header_buf,BSON_INT32,BSON_INT64);
    my ($starting_from,$number_returned) = unpack 'V2',substr($header_buf,BSON_INT32+BSON_INT64);
    return ($response_flags,$cursor_id,$starting_from,$number_returned);
}

sub _read_documents {
    
    # my ($self,$number_remaining,$cursor_id) = @_;
    # my $docs = [];
    # 
    # while ($number_remaining) {
    #     my $bson_buf = $self->receive_data(BSON_INT32);
    #     my $size = unpack('V',$bson_buf);
    #     $bson_buf = $bson_buf.$self->receive_data( $size- BSON_INT32 );
    #     # warn $doc_bson_buf;
    #     my $doc = bson_decode($bson_buf);
    #     push @{$docs},$doc;
    #     $number_remaining--;
    # }
    my ($self,$doc_message_length,$cursor_id) = @_;
    my $remaining = $doc_message_length;
    my $bson_buf;
    # do {
    #     my $buf_len = $remaining > 4096? 4096:$remaining;
    #     $bson_buf .= $self->receive_data($buf_len);
    #     $remaining -= $buf_len;
    # } while ($remaining >0 );
    
    $bson_buf = $self->receive_data($doc_message_length);
    return unless $bson_buf;
    # warn "#_read_documents:bson_buf size:".length($bson_buf);
    # my $docs = decode_bson_documents($bson_buf,length($bson_buf));
    # warn '#_read_documents decode_bson_documents ...';
    my $docs = decode_bson_documents($bson_buf);
    # warn "docs:$docs";
    # warn "#_read_documents:".Dumper($docs)."\n";
    
    
    return $docs;
}

sub database_names {
    my ($self) = @_;
    my $ret = $self->get_database('admin')->run_command({ listDatabases => 1 });
    return map { $_->{name} } @{ $ret->{databases} };
}


sub get_database {
    my ($self, $database_name) = @_;
    return AnyMongo::Database->new(
        _connection => $self,
        name        => $database_name,
    );
}

sub authenticate {
    my ($self, $dbname, $username, $password, $is_digest) = @_;
    my $hash = $password;

    # create a hash if the password isn't yet encrypted
    if (!$is_digest) {
        $hash = Digest::MD5::md5_hex("${username}:mongo:${password}");
    }

    # get the nonce
    my $db = $self->get_database($dbname);
    my $result = $db->run_command({getnonce => 1});
    if (!$result->{'ok'}) {
        return $result;
    }

    my $nonce = $result->{'nonce'};
    my $digest = Digest::MD5::md5_hex($nonce.$username.$hash);

    # run the login command
    my $login = tie(my %hash, 'Tie::IxHash');
    %hash = (authenticate => 1,
             user => $username, 
             nonce => $nonce,
             key => $digest);
    $result = $db->run_command($login);

    return $result;
}

__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 NAME

MongoDB::AnyEvent::Connection 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

