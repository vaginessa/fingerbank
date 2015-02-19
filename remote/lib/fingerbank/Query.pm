package fingerbank::Query;

use Moose;
use namespace::autoclean;

use JSON;
use LWP::UserAgent;
use Module::Load;
use POSIX;

use fingerbank::Config;
use fingerbank::Error qw(is_error is_success);
use fingerbank::FilePaths;
use fingerbank::Log qw(get_logger);
use fingerbank::Model::Combination;
use fingerbank::Model::Device;

# The query keys required to fullfil a match
# - We load the appropriate module for each of the different query keys based on their name
# - We declare object attributes for each of the different query keys based on their name
our @query_keys = ('DHCP_Fingerprint', 'DHCP_Vendor', 'User_Agent', 'MAC_Vendor');
foreach my $key ( @query_keys ) {
    load "fingerbank::Model::$key";
    has $key . '_value' => (is => 'rw', isa => 'Str', default => "");
    has $key . '_id'    => (is => 'rw', isa => 'Str', default => "");
}

has 'device_id' => (is => 'rw', isa => 'Str');
has 'combination_id' => (is => 'rw', isa => 'Str');

=head2 match

=cut
sub match {
    my ( $self, $args ) = @_;
    my $logger = get_logger;

    # Initialize status variables
    # We set the status_code to OK so we can proceed
    my ( $status_code, $status_msg ) = $fingerbank::Status::OK;

    # We assign the value of each key to the corresponding object attribute (ie.: DHCP_Fingerprint_value)
    # Note: We must have all of the keys in the query, either with a value or with ''
    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_value';
        $self->$concatenated_key($args->{lc($key)}) if ( defined($args->{lc($key)}) );
    }

    ( $status_code, $status_msg ) = $self->getQueryKeyIDs;
    ( $status_code, $status_msg ) = $self->getCombinationID if ( is_success($status_code) );

    # All preconditions succeed, we build  the device resultset and returns it
    if ( is_success($status_code) ) {
        return $self->_buildResult;
    }
    # We were unable to fullfil a match locally
    # Most of the time, preconditions may have failed.
    else {
        my $ua = LWP::UserAgent->new;
        my $query_args = encode_json($args);

        my $req = HTTP::Request->new( GET => $UPSTREAM_QUERY_URL.$API_KEY);
        $req->content_type('application/json');
        $req->content($query_args);

        my $res = $ua->request($req);
        return (decode_json($res->content));
    }
}

=head2 getQueryKeyIDs

=cut
sub getQueryKeyIDs {
    my ( $self ) = @_;
    my $logger = get_logger;

    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_value';

        # We build the search query
        # ie: SELECT get_column FROM schema WHERE search_for = term;
        # Schema is handled on the CRUD side. See L<fingerbank::Base::CRUD::search>
        my %query = (
            search_for  =>  'value',                    # From which column we want to search
            term        =>  $self->$concatenated_key,   # The value we are searching from
            get_column  =>  'id',                       # The value of which column do we want
        );

        my ( $status_code, $result ) = "fingerbank::Model::$key"->search(\%query);

        # If we cannot find any ID for a key, we need to return an error code since it is a precondition and we cannot continue
        if ( is_error($status_code) ) {
            my $status_msg = "Cannot find any ID for $key in " . (caller(0))[3];
            $logger->error($status_msg);

            # We record the unmatched query key if configured to do so
            $self->_recordUnmatched($key, $self->$concatenated_key);

            return ( $fingerbank::Status::PRECONDITION_FAILED, $status_msg );
            last
        }

        $self->{$key . '_id'} = $result;
    }

    return $fingerbank::Status::OK;
}

=head2 getCombinationID

Something

=cut
sub getCombinationID {
    my ( $self ) = @_;
    my $logger = get_logger;

    # Building the query bindings
    # Those are the IDs for each query keys. Order is important since the SQL query is dependant
    # See L<fingerbank::Base::Schema::CombinationMatch>
    my @bindings = ();
    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_id';
        push @bindings, $self->$concatenated_key;
    }

    # Looking for best matching combination in schemas
    # Sorting by match is handled by the SQL query itself. See L<fingerbank::Base::Schema::CombinationMatch>
    foreach my $schema ( @fingerbank::DB::schemas ) {
        my $db = fingerbank::DB->connect($schema);
        my $resultset = $db->resultset('CombinationMatch')->search( {},
            { bind => [ @bindings, @bindings ] }
        )->first;

        if ( defined($resultset) ) {
            $self->combination_id($resultset->id);
            $logger->info("Found combination ID '" . $self->combination_id . "' in schema '$schema'");
            next;
        }

        $logger->debug("No match found in schema '$schema'");
    }

    return $fingerbank::Status::OK;
}

=head2 _buildResult

=cut
sub _buildResult {
    my ( $self ) = @_;
    my $logger = get_logger;

    my $result = {};

    # Get the combination info
    my $combination = fingerbank::Model::Combination->read($self->combination_id);
    foreach my $key ( keys %$combination ) {
        $result->{$key} = $combination->{$key};
    }

    # Get device info
    my $device = fingerbank::Model::Device->read($combination->{device_id}, 1);
    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    return $result;
}

=head2 _recordUnmatched

=cut
sub _recordUnmatched {
    my ( $self, $key, $value ) = @_;
    my $logger = get_logger;

    # Are we configured to do so ?
    if ( !$RECORD_UNMATCHED ) {
        $logger->debug("Not configured to keep track of unmatched query keys. Skipping");
        return;
    }

    $logger->debug("Record the unmatched query key '$key' with value " . $value . " in the 'unmatched' table of 'Local' database");

    # We first check if we already have the entry, if so we simply increment the occurence number
    my $db = fingerbank::DB->connect('Local');
    my $resultset = $db->resultset('Unmatched')->search({
        type    => { 'like', $key },
        value   => { 'like', $value},
    });

    # We do not have an existing entry for that query key. Creating a new one
    if ( $resultset eq 0 ) {
        $logger->info("New unmatched '$key' query key detected with value '$value'. Adding an entry to the 'unmatched' table of 'Local' database");
        my %args = (
            type => $key,
            value => $value,
            created_at => strftime("%Y-%m-%d %H:%M:%S", localtime(time)),
            updated_at => strftime("%Y-%m-%d %H:%M:%S", localtime(time)),
        );
        my $unmatched_key = $db->resultset('Unmatched')->create(\%args);
    }

    # We have an existing entry for that query key. Incrementing the occurence number
    else {
        $logger->info("Existing unmatched '$key' query key detected with value '$value'. Incrementing the number of occurence");
        my $occurence = $resultset->first->occurence;
        $occurence ++;
        my %args = (
            updated_at  => strftime("%Y-%m-%d %H:%M:%S", localtime(time)),
            occurence   => $occurence,
        );
        my $unmatched_key = $db->resultset('Unmatched')->update(\%args);
    }

}


=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;
