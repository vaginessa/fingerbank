package fingerbank::Base::Discoverer;

use Moose;
use fingerbank::Status;

has 'supersedes' => (is => 'rw', isa => 'Bool', default => sub {0}, coerce => sub {0});

sub match {
  return $fingerbank::Status::NOT_FOUND;
}
