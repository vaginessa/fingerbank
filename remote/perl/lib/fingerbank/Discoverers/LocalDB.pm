package fingerbank::Discoverers::LocalDB;

use Moose;

use fingerbank::Config;
use fingerbank::Constant qw($TRUE);
use fingerbank::Log;
use fingerbank::Model::Combination;
use fingerbank::Model::Device;
use fingerbank::Util qw(is_enabled is_disabled is_error is_success);
use fingerbank::Result;

sub match {
    my ( $args, $other_results ) = @_;
    my $logger = fingerbank::Log::get_logger;

    # Initialize status variables
    # We set the status to OK so we can proceed
    my ($status, $status_msg) = $fingerbank::Status::OK;

    my $result = fingerbank::Result->new;

    # TODO: Review that part to make it less "hacky"
    $args->{'mac_vendor'} = $args->{'mac'};

    # We assign the value of each key to the corresponding object attribute (ie.: DHCP_Fingerprint_value)
    # Note: We must have all of the keys in the query, either with a value or with ''
    $logger->debug("Attempting to match a device with the following attributes:");
    foreach my $key ( @fingerbank::Constant::QUERY_PARAMETERS ) {
        my $concatenated_key = $key . '_value';
        $result->$concatenated_key($args->{lc($key)}) if ( defined($args->{lc($key)}) );
        $logger->debug("- $concatenated_key: '" . $result->$concatenated_key . "'");
    }

    ($status, $status_msg) = $result->_getQueryKeyIDs;
    ($status, $status_msg) = $result->_getCombinationID if ( is_success($status) );

    # Upstream is configured (an API key is configured and interrogate upstream is enabled) with an unexact match, we go upstream
    if ( !$result->{combination_is_exact} && fingerbank::Config::is_api_key_configured && fingerbank::Config::do_we_interrogate_upstream ) {
        $logger->info("Upstream is configured and unable to fullfil an exact match locally. Will ignore result from local database");
        return $fingerbank::Status::NOT_FOUND;
    } 
    # Either local match is exact or upstream is not configured, build local result
    else {
        $logger->info("Locally matched combination is exact. Build result") if $result->{combination_is_exact};
        $logger->info("Building the result locally");
        ( $status, $result ) = $result->_buildResult if ( is_success($status) );
    }

    if ( is_success($status) ) {
        $result->{device_id} = $result->{device}->{id};
        return $result;
    }

    $logger->warn("Unable to fullfil a match either locally or using upstream Fingerbank project.");
    return $fingerbank::Status::NOT_FOUND;
}

1;

