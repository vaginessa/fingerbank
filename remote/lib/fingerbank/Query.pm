package fingerbank::Query;

use Moose;
use namespace::autoclean;

use JSON;
use LWP::UserAgent;
use Module::Load;
use POSIX;

use fingerbank::Config;
use fingerbank::Constant qw($TRUE);
use fingerbank::Log;
use fingerbank::Model::Combination;
use fingerbank::Model::Device;
use fingerbank::Util qw(is_enabled is_disabled is_error is_success);

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
    my $logger = fingerbank::Log::get_logger;

    # Initialize status variables
    # We set the status to OK so we can proceed
    my ($status, $status_msg) = $fingerbank::Status::OK;

    # TODO: Review that part to make it less "hacky"
    $args->{'mac_vendor'} = $args->{'mac'};

    # We assign the value of each key to the corresponding object attribute (ie.: DHCP_Fingerprint_value)
    # Note: We must have all of the keys in the query, either with a value or with ''
    $logger->debug("Attempting to match a device with the following attributes:");
    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_value';
        $self->$concatenated_key($args->{lc($key)}) if ( defined($args->{lc($key)}) );
        $logger->debug("- $concatenated_key: '" . $self->$concatenated_key . "'");
    }

    ($status, $status_msg) = $self->_getQueryKeyIDs;
    ($status, $status_msg) = $self->_getCombinationID if ( is_success($status) );

    my $result;

    # All preconditions succeed, we build the device resultset and returns it
    if ( is_success($status) ) {
        ( $status, $result ) = $self->_buildResult;
        $result->{'SOURCE'} = "Local";
        $self->{device_id} = $result->{device}->{id};
        return $result;
    }

    # We were unable to fullfil a match locally
    # Most of the time, preconditions may have failed.    
    my $Config = fingerbank::Config::get_config;
    my $interrogate_upstream = $Config->{'upstream'}{'interrogate'};
    ( $status, $result ) = $self->_interrogateUpstream($args) if is_enabled($interrogate_upstream);
    if ( is_success($status) ) {
        $result->{'SOURCE'} = "Upstream";
        $self->{device_id} = $result->{device}->{id};
        return $result;
    }

    $logger->warn("Unable to fullfil a match either locally or using upstream Fingerbank project.");
    return $fingerbank::Status::NOT_FOUND;
}

=head2 _getQueryKeyIDs

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _getQueryKeyIDs {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_value';
        $logger->debug("Attempting to find an ID for '$key' with value '" . $self->$concatenated_key . "'");

        my $query = {};
        $query->{'value'} = $self->$concatenated_key;

        # MAC_Vendor key is different in the way we store the values in the database. Need to handle it
        if ( $key eq 'MAC_Vendor' ) {
            $query->{'mac'} = delete $query->{'value'}; # The 'value' column is the 'mac' column in this specific case
            my $mac = $query->{'mac'};
            $mac =~ s/[:|\s|-]//g;      # Removing separators
            $mac = lc($mac);            # Lowercasing
            $mac = substr($mac, 0, 6);  # Only keep first 6 characters (OUI)
            $query->{'mac'} = $mac;
            $logger->debug("Attempting to find an ID for '$key'. This is a special case. Using mangled value '$mac'");
        }

        my ($status, $result) = "fingerbank::Model::$key"->find([$query, { columns => ['id'] }]);
       
        if ( is_error($status) ) {
            my $status_msg = "Cannot find any ID for '$key' with value '" . $self->$concatenated_key . "'";
            $logger->warn($status_msg);

            # We record the unmatched query key if configured to do so
            my $record_unmatched = fingerbank::Config::get_config('query', 'record_unmatched');
            $self->_recordUnmatched($key, $self->$concatenated_key) if is_enabled($record_unmatched);

            return ( $fingerbank::Status::NOT_FOUND, $status_msg );
            last
        }

        $self->{$key . '_id'} = $result->id;
        $logger->debug("Found ID '" . $self->{$key . '_id'} . "' for '$key' with value '" . $self->$concatenated_key . "'");
    }

    return $fingerbank::Status::OK;
}

=head2 _getCombinationID

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _getCombinationID {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    # Building the query bindings
    # Those are the IDs for each query keys. Order is important since the SQL query is dependant
    # See L<fingerbank::Base::Schema::CombinationMatch>
    $logger->debug("Attempting to find a combination with the following ID(s):");
    my @bindings = ();
    foreach my $key ( @query_keys ) {
        my $concatenated_key = $key . '_id';
        push @bindings, $self->$concatenated_key;
        $logger->debug("- $concatenated_key: '" . $self->$concatenated_key . "'");
    }

    # Looking for best matching combination in schemas
    # Sorting by match is handled by the SQL query itself. See L<fingerbank::Base::Schema::CombinationMatch>
    foreach my $schema ( @fingerbank::DB::schemas ) {
        my $db = fingerbank::DB->connect($schema);
        my $resultset = $db->resultset('CombinationMatch')->search({}, { bind => [ @bindings, @bindings, $self->MAC_Vendor_id ] })->first;
        if ( defined($resultset) ) {
            $self->combination_id($resultset->id);
            $logger->info("Found combination ID '" . $self->combination_id . "' in schema '$schema'");
            last;
        }

        $logger->debug("No combination ID found in schema '$schema'");
    }

    if ( !defined($self->combination_id) ) {
        my $status_msg = "Cannot find any combination ID in any schemas";
        $logger->warn($status_msg);
        return ( $fingerbank::Status::NOT_FOUND, $status_msg );
    }

    return $fingerbank::Status::OK;
}

=head2 _buildResult

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _buildResult {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $result = {};

    # Get the combination info
    my $combination = fingerbank::Model::Combination->read($self->combination_id);
    foreach my $key ( keys %$combination ) {
        $result->{$key} = $combination->{$key};
    }

    # Get device info
    my $device = fingerbank::Model::Device->read($combination->{device_id}, $TRUE);
    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    return ( $fingerbank::Status::OK, $result );
}

=head2 _interrogateUpstream

=cut

sub _interrogateUpstream {
    my ( $self, $args ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my ( $status, $result );

    my $Config = fingerbank::Config::get_config;    

    # Are we configured to do so ?
    my $interrogate_upstream = $Config->{'upstream'}{'interrogate'};
    if ( is_disabled($interrogate_upstream) ) {
        $logger->debug("Not configured to interrogate upstream Fingerbank project with unknown match. Skipping");
        return;
    }

    # Is an API key configured ?
    if ( !fingerbank::Config::is_api_key_configured ) {
        $status = $fingerbank::Status::UNAUTHORIZED;
        $result = "Can't communicate with Fingerbank project without a valid API key.";
        $logger->warn($result);
        return ( $status, $result );
    }

    $logger->debug("Attempting to interrogate upstream Fingerbank project");

    my $ua = LWP::UserAgent->new;
    my $query_args = encode_json($args);

    my $req = HTTP::Request->new( GET => $Config->{'upstream'}{'interrogate_url'}.$Config->{'upstream'}{'api_key'});
    $req->content_type('application/json');
    $req->content($query_args);

    my $res = $ua->request($req);

    if ( $res->is_success ) {
        $status = $fingerbank::Status::OK;
        $result = decode_json($res->content);
        $logger->info("Successfully interrogate upstream Fingerbank project for matching");
    } else {
        $status = $fingerbank::Status::INTERNAL_SERVER_ERROR;
        $result = "An error occured while interrogating upstream Fingerbank project";
        $logger->warn($result . ": " . $res->status_line);
    }

    return ( $status, $result );
}

=head2 _recordUnmatched

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _recordUnmatched {
    my ( $self, $key, $value ) = @_;
    my $logger = fingerbank::Log::get_logger;

    # Are we configured to do so ?
    my $record_unmatched = fingerbank::Config::get_config('query', 'record_unmatched');
    if ( is_disabled($record_unmatched) ) {
        $logger->debug("Not configured to keep track of unmatched query keys. Skipping");
        return;
    }

    $logger->debug("Attempting to record the unmatched query key '$key' with value '$value' in the 'unmatched' table of 'Local' database");

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

=head2 isWindows

Test if device (name or ID) is Windows based

=cut

sub isWindows {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $WINDOWS_PARENT_ID = 1;
    $logger->debug("Testing if device '$device' is a Windows based device");

    my $result = fingerbank::Model::Device->is_a($device, $WINDOWS_PARENT_ID);

    $logger->info("Device '$device' is a Windows based device") if $result;

    return $result;
}

=head2 isMacOS

Test if device (name or ID) is MacOS based

=cut

sub isMacOS {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $MACOS_PARENT_ID = 2;
    $logger->debug("Testing if device '$device' is a MacOS based device");

    my $result = fingerbank::Model::Device->is_a($device, $MACOS_PARENT_ID);

    $logger->info("Device '$device' is a MacOS based device") if $result;

    return $result;
}

=head2 isAndroid

Test if device (name or ID) is Android based

=cut

sub isAndroid {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $ANDROID_PARENT_ID = 202;
    $logger->debug("Testing if device '$device' is an Android based device");

    my $result = fingerbank::Model::Device->is_a($device, $ANDROID_PARENT_ID);

    $logger->info("Device '$device' is an Android based device") if $result;

    return $result;
}

=head2 isIOS

Test if device (name or ID) is IOS based

=cut

sub isIOS {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $IOS_PARENT_ID = 193;
    $logger->debug("Testing if device '$device' is an IOS based device");

    my $result = fingerbank::Model::Device->is_a($device, $IOS_PARENT_ID);

    $logger->info("Device '$device' is an IOS based device") if $result;

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
