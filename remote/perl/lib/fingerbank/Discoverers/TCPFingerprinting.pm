package fingerbank::Discoverers::TCPFingerprinting;

use Moose;

sub match {
    my ($args, $other_results) = @_;
    my $logger = fingerbank::Log::get_logger;
    $logger->info("Change me. I'm not doing anything.");
    return $fingerbank::Status::NOT_FOUND; 
}

1;
