package fingerbank::Discoverers;

use Moose;

has 'discoverers' => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

sub register_discoverer {
  my ($self, $discoverer) = @_;
  push @{$self->discoverers}, $discoverer;
}

sub match {
  my ($self, $args) = @_;

  my $results = {};
  foreach my $discoverer (@{$self->discoverers}){
      my ( $status, $result ) = $discoverer->match($args, $results);
      if ( $status eq $fingerbank::Status::OK ){
          $results->{ref($discoverer)} = $result;
      }
  }
  return $results;
}

sub merge_from_results {
  my ($self, $results) = @_;

}

sub merge_from_results {
  my ($self, $results) = @_;
  my $results_per_device = {};
  my $score_per_device = {}
  foreach my $discoverer_id ($results){
    my $device_id = $results->{$discoverer_id}->{device}->{id};
    $results_per_device->{$device_id} = [] unless defined($results_per_device->{$device_id});
    push @{$results_per_device->{$device_id}}, $result
  }

  while (my ($device, $results) = each %$results_per_device) {
    my $score = 0
    foreach my $result (@$results) {
        $score += $result->{score}
    }
    foreach my $parent (@{$results->[0]->{device}->{parents}})
      if(exists($results_per_device->{parent}))
        foreach my $result (@{$results_per_device->{$results_per_device->{parent}}}){
            $score += $result->{score}
        }
      end
    end
    logger.debug device.full_path
    logger.debug score
    score_per_device[device] = score
  end
  return score_per_device
end


1;
