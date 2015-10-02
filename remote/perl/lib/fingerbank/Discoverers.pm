package fingerbank::Discoverers;

use Moose;

has 'discoverers' => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

sub register_discoverer {
  my ($self, $discoverer) = @_;
  push @{$self->discoverers}, $discoverer;
}

sub match_best {
    my ($self, $args) = @_;
    my $logger = fingerbank::Log::get_logger;
    my ($results, $results_array) = $self->match_all($args);
    my @ordered = reverse sort { $results->{$a} <=> $results->{$b} } keys %$results;
    my $best_match = $results_array->[0];
    my $pretty_args = '[' . join(',', map { "'$_' : '$args->{$_}'" } keys %$args) . ']';
    if($best_match){
        $logger->debug("Found '$best_match->{device}->{name}' with score $best_match->{score} for args : $pretty_args");
        return $best_match;
    }
    else {
        $logger->debug("Could not find any match with args : $pretty_args");
    }
}

sub match_all {
    my ($self, $args) = @_;

    my $results = {};
    foreach my $discoverer (@{$self->discoverers}){
        my ( $status, $result ) = $discoverer->match($args, $results);
        if ( $status eq $fingerbank::Status::OK ){
            $results->{ref($discoverer)} = $result;
        }
    }
    my ($sorted, $results_array) = $self->merge_from_results($results);
    return ($sorted, $results_array);
}

sub merge_from_results {
    my ($self, $results) = @_;
    my $results_per_device = {};
    my $score_per_result = {};
    my @results_array;
    # we sort each result by the resulting device
    foreach my $discoverer_id (keys %$results){
        my $device_id = $results->{$discoverer_id}->{device}->{id};
        $results_per_device->{$device_id} = [] unless defined($results_per_device->{$device_id});
        push @{$results_per_device->{$device_id}}, $results->{$discoverer_id};
    }

    while (my ($device, $results) = each %$results_per_device) {
        my $score = 0;
        # adding each result with same hit
        foreach my $result (@$results) {
            $score += $result->{score}
        }
        # cycling through this device parents and adding the scores found
        # from hits on it's parents
        foreach my $parent (@{$results->[0]->{device}->{parents}}){
            my $parent_id = $parent->{id};
            if(exists($results_per_device->{$parent_id})) {
                foreach my $result (@{$results_per_device->{$parent_id}}){
                    $score += $result->{score}
                }
            }
        }
        $score_per_result->{@results_array} = $score;
        $results->[0]->{score} = $score;
        push @results_array, $results->[0];
    }
    return ($score_per_result, \@results_array);
}


1;
