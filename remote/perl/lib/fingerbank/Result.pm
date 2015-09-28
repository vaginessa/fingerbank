package fingerbank::Result;

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
foreach my $key ( @fingerbank::Constant::QUERY_PARAMETERS ) {
    load "fingerbank::Model::$key";
    has $key . '_value' => (is => 'rw', isa => 'Str', default => "");
    has $key . '_id'    => (is => 'rw', isa => 'Str', default => "");
}

has 'device_id' => (is => 'rw', isa => 'Str');
has 'combination_id' => (is => 'rw', isa => 'Str');
has 'combination_is_exact' => (is => 'rw', isa => 'Str');

=head2 _buildResult

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _buildResult {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $result = {};

    # Get the combination info
    my ( $status, $combination ) = fingerbank::Model::Combination->read($self->combination_id);
    return $status if ( is_error($status) );

    foreach my $key ( keys %$combination ) {
        $result->{$key} = $combination->{$key};
    }

    # Get device info
    ( $status, my $device ) = fingerbank::Model::Device->read($combination->{device_id}, $TRUE);
    return $status if ( is_error($status) );

    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    # Tracking down from where the result is coming
    $result->{'SOURCE'} = "Local";

    return ( $fingerbank::Status::OK, $result );
}


=head2 _getQueryKeyIDs

Not meant to be used outside of this class. Refer to L<fingerbank::Query::match>

=cut

sub _getQueryKeyIDs {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    foreach my $key ( @fingerbank::Constant::QUERY_PARAMETERS ) {
        my $concatenated_key = $key . '_value';
        $logger->debug("Attempting to find an ID for '$key' with value '" . $self->$concatenated_key . "'");

        my $query = {};
        $query->{'value'} = $self->$concatenated_key;

        # MAC_Vendor key is different in the way we store the values in the database. Need to handle it
        if ( $key eq 'MAC_Vendor' ) {
            if ( $query->{'value'} eq '' ) {
                $logger->debug("Attempting to find an ID for 'MAC_Vendor' with empty value. This is a special case. Returning 'NULL'");
                $self->{$key . '_id'} = 'NULL';
                next;
            }
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
    foreach my $key ( @fingerbank::Constant::QUERY_PARAMETERS ) {
        my $concatenated_key = $key . '_id';
        push @bindings, $self->$concatenated_key;
        $logger->debug("- $concatenated_key: '" . $self->$concatenated_key . "'");
    }

    # Looking for best matching combination in schemas
    # Sorting by match is handled by the SQL query itself. See L<fingerbank::Base::Schema::CombinationMatch>
    foreach my $schema ( @fingerbank::DB::schemas ) {
        my $db = fingerbank::DB->new(schema => $schema);
        if ( $db->isError ) {
            $logger->warn("Cannot read from 'CombinationMatch' table in schema 'Local'. DB layer returned '" . $db->statusCode . " - " . $db->statusMsg . "'");
            return $fingerbank::Status::INTERNAL_SERVER_ERROR;
        }

        my $resultset = $db->handle->resultset('CombinationMatch')->search({}, { bind => [ @bindings ] })->first;
        if ( defined($resultset) ) {
            $self->combination_id($resultset->id);
            $logger->info("Found combination ID '" . $self->combination_id . "' in schema '$schema'");

            # Check if exact match
            my $matched_keys = 0;
            foreach ( @fingerbank::Constant::QUERY_PARAMETERS ) {
                my $concatenated_key = $_ . '_id';
                my $lc_concatenated_key = lc($concatenated_key);
                $matched_keys ++ if ( $resultset->$lc_concatenated_key eq $self->$concatenated_key );
            }
            my $exact_matched_keys = @fingerbank::Constant::QUERY_PARAMETERS;
            $self->combination_is_exact($TRUE) if ( $matched_keys == $exact_matched_keys );

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
    my $db = fingerbank::DB->new(schema => 'Local');
    if ( $db->isError ) {
        $logger->warn("Cannot read from 'Unmatched' table in schema 'Local'. DB layer returned '" . $db->statusCode . " - " . $db->statusMsg . "'");
        return;
    }

    my $resultset = $db->handle->resultset('Unmatched')->search({
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
        my $unmatched_key = $db->handle->resultset('Unmatched')->create(\%args);
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
        my $unmatched_key = $db->handle->resultset('Unmatched')->update(\%args);
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

    $logger->debug("Device '$device' is a Windows based device") if $result;

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

    $logger->debug("Device '$device' is a MacOS based device") if $result;

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

    $logger->debug("Device '$device' is an Android based device") if $result;

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

    $logger->debug("Device '$device' is an IOS based device") if $result;

    return $result;
}

1;
