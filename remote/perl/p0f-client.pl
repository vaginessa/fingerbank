#!/usr/bin/perl

use strict;
use warnings;

my $payload = pack("I C CCCC", 1345340929, 4, 172, 20, 20, 156);
foreach my $i (1..12){
  $payload .= pack("n", 0);
  $i++;
}

use IO::Socket::UNIX;

my $socket = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => '/var/run/p0f.sock',
);

die "Can't create socket: $!" unless $socket;

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

if($result eq 16){
  print "Success ! Found data through p0f. \n";
  print Dumper(\%info);
}
elsif($result eq 32){
  print "Unknown device to p0f. \n";
}
elsif($result eq 0){
  print "Invalid p0f query \n";
}
