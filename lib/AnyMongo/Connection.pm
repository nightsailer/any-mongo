package AnyMongo::Connection;
# ABSTRACT: Asynchronous MongoDB::Connection
use strict;
use warnings;
use constant DEBUG => $ENV{ANYMONGO_DEBUG};
use Carp qw(croak);
use Data::Dumper;
use AnyEvent::Socket;
use AnyEvent::Handle;
use namespace::autoclean;
use Any::Moose;
extends qw(MongoDB::Connection);


has handler => (
    isa => 'Maybe[AnyEvent::Handle]',
    is  => 'ro',
    clearer  => 'clear_handler',
);

has master_handler => (
    isa => 'Maybe[AnyEvent::Handle]',
    is  => 'rw',
    clearer  => 'clear_master_handler',
);


sub _init {
    my ($self) = @_;
    eval "use ${_}" # no Any::Moose::load_class becase the namespaces already have symbols from the xs bootstrap
        for qw/AnyMongoDB::Database AnyMongoDB::Cursor MongoDB::OID/;
    $self->_prepare_conn($self->_get_hosts);
    if ($self->auto_connect) {
        $self->connect;
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
        if (! $self->{_connected_server_count}) {
            delete $self->{mongo_servers};
            croak "Failed to connect to any mongodb servers";
        }
        $self->{_is_connected} = 1;
        $args{cb}->($self) if $args{cb};
        $args{cv}->end if $args{cv};
    };
    foreach my $k ( keys %{ $self->{ mongo_servers} } ) {
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
    
    DEBUG and warn "connect to $server_key";
    
    my $server = $mongo_servers->{$server_key};
    $server->{guard} = tcp_connect $host,$port, sub {
        my ($fh, $host, $port) = @_;
        if (!$fh) {
            warn "failed to connect to $server_key";
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


sub _prepare_conn {
    my ($self,@hosts) = @_;
    my $servers = {};
    for my $h (@hosts) {
        my $key = $h->{host}.':'.$h->{port};
        $servers->{$key} = { %$h, connected => 0,handler => undef};
    }
    $self->{mongo_servers} = $servers;
}

sub find_master {
    my ($self) = @_;
    return unless $self->{master_id};
    my $mongo_servers = $self->{mongo_servers};
    my $master_id = $self->{master_id};
    $self->master_handler($mongo_servers->{$master_id});
    # todo: real find master work
}




__PACKAGE__->meta->make_immutable (inline_destructor => 0);

1;
__END__


=head1 NAME

MongoDB::AnyEvent::Connection 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

