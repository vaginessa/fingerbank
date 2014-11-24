package fingerbank::Query;

use Moose;
use namespace::autoclean;

use JSON;
use LWP::UserAgent;
use Module::Load;

use fingerbank::Combination;
use fingerbank::Device;
use fingerbank::Error qw(is_error is_success);
use fingerbank::Log qw(get_logger);

# The query keys required to fullfil a match
# - We load the appropriate module for each of the different query keys based on their name
# - We declare object attributes for each of the different query keys based on their name
our @query_keys = ('DHCP_Fingerprint', 'DHCP_Vendor', 'User_Agent', 'MAC_Vendor');
foreach my $key ( @query_keys ) {
    load "fingerbank::$key";
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
    my ( $status_code, $status_msg ) = $STATUS::OK;

    # We assign the value of each key to the corresponding object attribute (ie.: DHCP_Fingerprint_value)
    # Note: We must have all of the keys in the query, either with a value or with ''
    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_value';
        $self->$concatenated_key($args->{lc($key)}) if ( defined($args->{lc($key)}) );
#        my $keyObj = "fingerbank::$key"->new;
#        $keyObj->content($args->{lc($key)}) if ( defined($args->{lc($key)}) );
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
        my $upstream_api_url = "https://fingerbank.inverse.ca/api/v1/combinations/interogate?key=";
        my $api_key = "";
        my $ua = LWP::UserAgent->new;
        my $query_args = encode_json($args);

        my $req = HTTP::Request->new( GET => $upstream_api_url.$api_key);
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
#        my $keyObj = "fingerbank::$key"->new;

        # We build the search query
        # ie: SELECT get_column FROM schema WHERE search_for = term;
        # Schema is handled on the CRUD side. See L<fingerbank::Base::CRUD::search>
        my %query = (
            search_for  =>  'value',                    # From which column we want to search
            term        =>  $self->$concatenated_key,   # The value we are searching from
#            term        => $keyObj->content,
            get_column  =>  'id',                       # The value of which column do we want
        );

        my ( $status_code, $result ) = "fingerbank::$key"->search(\%query);

        # If we cannot find any ID for a key, we need to return an error code since it is a precondition and we cannot continue
        if ( is_error($status_code) ) {
            my $status_msg = "Cannot find any ID for $key in " . (caller(0))[3];
            $logger->error($status_msg);
            return ( $STATUS::PRECONDITION_FAILED, $status_msg );
            last
        }

        $self->{$key . '_id'} = $result;
#        $keyObj->id($result);
    }

    return $STATUS::OK;
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
#        my $keyObj = "fingerbank::$key"->new;
#        push @bindings, $keyObj->id;
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
#            my $combinationObj = fingerbank::Combination->new;
#            $combinationObj->id($resultset->id);
#            $logger->info("Found combination ID '" . $combinationObj->id . "' in schema '$schema'");
            next;
        }

        $logger->debug("No match found in schema '$schema'");
    }

    return $STATUS::OK;
}

=head2 _buildResult

=cut
sub _buildResult {
    my ( $self ) = @_;
    my $logger = get_logger;

    my $result = {};

    # Get the combination info
    my $combination = fingerbank::Combination->read($self->combination_id);
    foreach my $key ( keys %$combination ) {
        $result->{$key} = $combination->{$key};
    }

    # Get device info
    my $device = fingerbank::Device->read($combination->{device_id});
    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    # Get parent(s)
    if ( defined($device->{parent_id}) ) {
        my $parent_exists = 1;
        my $parent_id = $device->{parent_id};
        my @parents;
        my $iteration = 0;
        while ( $parent_exists ) {
            my $parent = fingerbank::Device->read($parent_id);
            foreach my $key ( keys %$parent ) {
                $parents[$iteration]{$key} = $parent->{$key};
            }
            $iteration ++;
            $parent_id = $parent->{parent_id} if ( defined($parent->{parent_id}) );
            $parent_exists = 0 if ( !defined($parent->{parent_id}) );
        }
        $result->{device}->{parents} = \@parents;
    }

    return $result;
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
