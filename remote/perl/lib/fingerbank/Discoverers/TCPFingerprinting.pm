package fingerbank::Discoverers::TCPFingerprinting;

use Moose;

use strict;
use warnings;

use fingerbank::Constant qw($TRUE);
use fingerbank::Status;
use fingerbank::Util qw(is_error is_success);

use IO::Socket::UNIX;

sub match {
    my ($self, $args, $other_results) = @_;
    my $logger = fingerbank::Log::get_logger;
    $logger->info("Trying to interrogate p0f with IP $args->{ip}.");
 
    my @parts = split '\.', $args->{ip};

    my $payload = pack("I C CCCC", 1345340929, 4, @parts);
    # We pad zeros at the end as the IP can extend up to 16 (for IPv6)
    foreach my $i (1..12){
        $payload .= pack("n", 0);
        $i++;
    }

    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => '/var/run/p0f.sock',
    );

    unless($socket){
        my $msg = "Can't connect to p0f socket: $!";
        $logger->error($msg);
        return ($fingerbank::Status::INTERNAL_SERVER_ERROR, $msg);
    }

    $socket->send($payload);

    my $response;
    $socket->recv($response, 236);

    use Data::Dumper;
    my ($magic, $result, %info);

    ($magic, $result, $response) = unpack("I I a*", $response);
    ($info{first_seen}, $info{last_seen}, $info{total_conn}, $response) = unpack("I I I a*", $response); 
    ($info{uptime_min}, $info{up_mod_days},$response) = unpack("I I a*", $response); 
    ($info{last_nat}, $info{last_chg}, $response) = unpack("I I a*", $response); 
    ($info{last_nat}, $info{bad_sw}, $info{os_match_q}, $response) = unpack("s C C a*", $response); 
    ($info{os_name}, $info{os_flavor}, $response) = unpack("a32 a32 a*", $response); 
    ($info{http_name}, $info{http_flavor}, $response) = unpack("a32 a32 a*", $response); 
    ($info{link_type}, $info{language}, $response) = unpack("a32 a32 a*", $response); 

    $info{os_name} = int($info{os_name});

    if($result eq 16){
        $logger->debug("Success ! Found data through p0f.");
        return $self->_buildResult(\%info);
    }
    elsif($result eq 32){
        $logger->debug("Unknown device to p0f.");
        return $fingerbank::Status::NOT_FOUND;
    }
    elsif($result eq 0){
        $logger->error("Invalid p0f query");
        return $fingerbank::Status::INTERNAL_SERVER_ERROR;
    }
    else {
        $logger->error("Unknown return code from p0f $result");
        return $fingerbank::Status::INTERNAL_SERVER_ERROR;
    }
}

sub _buildResult {
    my ($self, $info) = @_;
    my $result = {};

    $result->{score} = 30;

    # Get device info
    my ( $status, $device ) = fingerbank::Model::Device->read($info->{os_name}, $TRUE);
    return $status if ( is_error($status) );


    foreach my $key ( keys %$device ) {
        $result->{device}->{$key} = $device->{$key};
    }

    return ($fingerbank::Status::OK, $result);
}

1;
