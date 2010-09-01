package AnyMongo::Database;
# ABSTRACT: Asynchronous MongoDB::Database
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;

has _connection => (
    is       => 'ro',
    isa      => 'AnyMongo::Connection',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    Any::Moose::load_class("AnyMongo::Collection");
}

sub collection_names {
    my ($self) = @_;
    my $it = $self->get_collection('system.namespaces')->query({});
    return map {
        substr($_, length($self->name) + 1)
    } map { $_->{name} } $it->all;
}

sub get_collection {
    my ($self, $collection_name) = @_;
    return AnyMongo::Collection->new(
        _database => $self,
        name      => $collection_name,
    );
}

sub get_gridfs {
    my ($self, $prefix) = @_;
    $prefix = "fs" unless $prefix;

    my $files = $self->get_collection("${prefix}.files");
    my $chunks = $self->get_collection("${prefix}.chunks");

    return AnyMongo::GridFS->new(
        _database => $self,
        files => $files,
        chunks => $chunks,
    );
}

sub drop {
    my ($self) = @_;
    return $self->run_command({ 'dropDatabase' => 1 });
}

sub last_error {
    my ($self, $options) = @_;

    my $cmd = Tie::IxHash->new("getlasterror" => 1);
    if ($options) {
        $cmd->Push("w", $options->{w}) if $options->{w};
        $cmd->Push("wtimeout", $options->{wtimeout}) if $options->{wtimeout};
        $cmd->Push("fsync", $options->{fsync}) if $options->{fsync};
    }

    return $self->run_command($cmd);
}

sub run_command {
    my ($self, $command) = @_;
    my $obj = $self->get_collection('$cmd')->find_one($command);
    
    # use Data::Dumper;
    # warn "run_command:".Dumper($obj);
    
    return $obj if ref $obj && $obj->{ok};
    $obj->{'errmsg'};
}

sub eval {
    my ($self, $code, $args) = @_;

    my $cmd = tie(my %hash, 'Tie::IxHash');
    %hash = ('$eval' => $code,
             'args' => $args);

    my $result = $self->run_command($cmd);
    if (ref $result eq 'HASH' && exists $result->{'retval'}) {
        return $result->{'retval'};
    }
    else {
        return $result;
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 NAME

MongoDB::AnyEvent::Database 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

