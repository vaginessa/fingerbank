package fingerbank::Discoverers;

use Moose;

has 'discoverers' => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

sub register_discoverer {
  my ($self, $discoverer) = @_;
  push @{$self->discoverers}, $discoverer;
}

sub match {
  my ($self, $args) = @_;

  $self->discoverers->[0]->match($args);
}

1;
