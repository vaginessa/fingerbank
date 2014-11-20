package fingerbank::Schema::Local::Combination;

use Moose;
use namespace::autoclean;

BEGIN {extends 'fingerbank::Base::Schema::Combination'; }


package fingerbank::Schema::Local::CombinationMatch;

use Moose;
use namespace::autoclean;

BEGIN {extends 'fingerbank::Base::Schema::CombinationMatch'; }


1;
