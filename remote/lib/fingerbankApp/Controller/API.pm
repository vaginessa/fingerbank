package fingerbankApp::Controller::API;

use Moose;
use namespace::autoclean;

use Module::Load;

use fingerbank::Error qw(is_error is_success);
use fingerbank::Log qw(get_logger);
use fingerbank::Query;

BEGIN {extends 'Catalyst::Controller::REST'; }

our @query_keys = @fingerbank::Query::query_keys;
push (@query_keys, 'Device', 'Combination');
foreach my $key ( @query_keys ) {
    load "fingerbank::Model::$key";
}


sub dispatcher :Chained('/') :PathPart('api') :CaptureArgs(1) {
    my ( $self, $c, $key ) = @_;
    my $logger = get_logger;

    my ( $status_code, $status_msg );

    # Check if requested key is supported
    # We also use that ARRAY to HASH conversion to handle lower/upper case in package names
    my %valid_keys = map { lc($_) => $_ } @query_keys;
    if ( !exists($valid_keys{$key}) ) {
        $status_msg = "Requested key '$key' is not a valid one";
        $logger->warn($status_msg);
        $self->status_bad_request(
            $c,
            message => $status_msg,
        );
        $c->detach;
    }

    $c->stash->{key} = $valid_keys{$key};
}


=head1 METHODS

=cut

=head2 create

Create an entry. Returns the newly created entry

Will create a new custom entry (part of the 'Local' schema)

HTTP/POST

Usage: ./create by sending data using an HTTP POST

ie.: /device/create

Example of data:

See L<fingerbankApp::Controller::API::create_POST>

=cut
sub create :Chained('dispatcher') :Path('create') :Args(0) :ActionClass('REST') {}

=head2 read

Details of a specific entry based on the provided ID

HTTP/GET

Usage: ./read/<ID>

ie.: /device/read/42

See L<fingerbankApp::Controller::API::read_GET>

=cut
sub read :Chained('dispatcher') :Path('read') :Args(1) :ActionClass('REST') {}

=head2 update

Update an existing entry based on the provided ID. Return the updated entry

Only available to update a custom entry (part of the 'Local' schema)

HTTP/POST

Usage: ./update/<ID> by sending data using an HTTP POST

ie.: /device/update/l42

Example of data:

See L<fingerbankApp::Controller::API::update_POST>

=cut
sub update :Chained('dispatcher') :Path('update') :Args(1) :ActionClass('REST') {}

=head2 delete

Delete an existing entry based on the provided ID

Only available to delete a custom entry (part of the 'Local' schema)

HTTP/DELETE

Usage: ./delete/<ID>

ie.: /device/delete/l42

See L<fingerbankApp::Controller::API::delete_DELETE>

=cut
sub delete :Chained('dispatcher') :Path('delete') :Args(1) :ActionClass('REST') {}

=head2 list

List all the entries

HTTP/GET

Usage: ./list

ie.: /device/list

See L<fingerbankApp::Controller::API::list_GET>

=cut
sub list :Chained('dispatcher') :Path('list') :ActionClass('REST') {}

sub match :Path('match') :ActionClass('REST') {}

=head2 create_POST

See L<fingerbankApp::Controller::API::create>

=cut
sub create_POST {
    my ( $self, $c, $id ) = @_;
    my $logger = get_logger;

    my $query_data = $c->req->data;
    my $key = $c->stash->{key};

    # Make sure we have data to work with
    if ( !defined($query_data) ) {
        $self->status_bad_request(
            $c,
            message => "You must provide data to be able to create!",
        );
        $c->detach;
    }

    my ( $status_code, $entity ) = "fingerbank::Model::$key"->create($query_data);

    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    $self->status_ok(
        $c,
        entity => $entity,
    );
}

=head2 read_GET

See L<fingerbankApp::Controller::API::read>

=cut
sub read_GET {
    my ( $self, $c, $id ) = @_;
    my $logger = get_logger;

    my $key = $c->stash->{key};

    my ( $status_code, $entity ) = "fingerbank::Model::$key"->read($id);

    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    $self->status_ok(
        $c,
        entity => $entity,
    );
}

=head2 update_POST

See L<fingerbankApp::Controller::API::update>

=cut
sub update_POST {
    my ( $self, $c, $id ) = @_;
    my $logger = get_logger;

    my $query_data = $c->req->data;
    my $key = $c->stash->{key};

    # Make sure we have data to work with
    if ( !defined($query_data) ) {
        $self->status_bad_request(
            $c,
            message => "You must provide data to be able to update!",
        );
        $c->detach;
    }

    my ( $status_code, $entity ) = "fingerbank::Model::$key"->update($id, $query_data);

    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    $self->status_ok(
        $c,
        entity => $entity,
    );
}

=head2 delete_DELETE

See L<fingerbankApp::Controller::API::delete>

=cut
sub delete_DELETE {
    my ( $self, $c, $id ) = @_;
    my $logger = get_logger;

    my $key = $c->stash->{key};

    my ( $status_code, $entity ) = "fingerbank::Model::$key"->delete($id);

    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    $self->status_ok(
        $c,
        entity => $entity,
    );
}

=head2 list_GET

See L<fingerbankApp::Controller::API::list>

=cut
sub list_GET {
    my ( $self, $c ) = @_;
    my $logger = get_logger;

    my $key = $c->stash->{key};

    my ( $status_code, $entity ) = "fingerbank::Model::$key"->read;

    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    $self->status_ok(
        $c,
        entity => $entity,
    );
}

=head2 match_POST

See L<fingerbankApp::Controller::API::match>

=cut
sub match_POST {
    my ( $self, $c ) = @_;
    my $logger = get_logger;

    my $query_data = $c->req->data;

    # Make sure we have data to work with
    if ( !defined($query_data) ) {
        $self->status_bad_request (
            $c,
            message => "You must provide data to be able to match!",
        );
        $c->detach;
    }

    my ( $status_code, $entity ) = fingerbank::Query->match($query_data);

    # Check return status code in case of error
    if ( is_error($status_code) ) {
        $self->status_not_found(
            $c,
            message => $entity,
        );
        $c->detach;
    }

    # Return the result
    $self->status_ok (
        $c,
        entity => $entity,
    );
}

__PACKAGE__->meta->make_immutable;

1;
