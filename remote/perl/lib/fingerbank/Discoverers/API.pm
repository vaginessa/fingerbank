package fingerbank::Discoverers::API;

use Moose;

use JSON;

use fingerbank::Config;
use fingerbank::Constant qw($TRUE);
use fingerbank::Log;
use fingerbank::Model::Combination;
use fingerbank::Model::Device;
use fingerbank::Util qw(is_enabled is_disabled is_error is_success);

sub match {
    my ( $self, $args, $other_results ) = @_;
    my $logger = fingerbank::Log::get_logger;

    foreach my $discoverer_id (keys %$other_results){
        if($discoverer_id eq "fingerbank::Discoverers::LocalDB"){
            $logger->debug("Found a good hit in the Fingerbank local databases. Will not interrogate Upstream.");
            return $fingerbank::Status::NOT_FOUND;
        }
    }

    my $Config = fingerbank::Config::get_config;    

    # Are we configured to do so ?
    my $interrogate_upstream = $Config->{'upstream'}{'interrogate'};
    if ( is_disabled($interrogate_upstream) ) {
        $logger->debug("Not configured to interrogate upstream Fingerbank project with unknown match. Skipping");
        return $fingerbank::Status::NOT_IMPLEMENTED;
    }

    # Is an API key configured ?
    if ( !fingerbank::Config::is_api_key_configured ) {
        $logger->warn("Can't communicate with Fingerbank project without a valid API key.");
        return $fingerbank::Status::UNAUTHORIZED;
    }

    $logger->debug("Attempting to interrogate upstream Fingerbank project");

    my $ua = LWP::UserAgent->new;
    $ua->timeout(2);   # An interrogate query should not take more than 2 seconds
    my $query_args = encode_json($args);

    my $req = HTTP::Request->new( GET => $Config->{'upstream'}{'interrogate_url'}.$Config->{'upstream'}{'api_key'});
    $req->content_type('application/json');
    $req->content($query_args);

    my $res = $ua->request($req);

    if ( $res->is_success ) {
        $logger->info("Successfully interrogate upstream Fingerbank project for matching");
        my $result = decode_json($res->content);
        # Tracking down from where the result is coming
        $result->{'SOURCE'} = "Upstream";
        return ( $fingerbank::Status::OK, $result );
    } else {
        $logger->warn("An error occured while interrogating upstream Fingerbank project: " . $res->status_line);
        return $fingerbank::Status::INTERNAL_SERVER_ERROR;
    }

}

1;
