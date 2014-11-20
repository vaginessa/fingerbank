package fingerbank::Schema::Upstream::Combination;

use Moose;
use namespace::autoclean;

BEGIN {extends 'fingerbank::Base::Schema::Combination'; }


package fingerbank::Schema::Upstream::CombinationMatch;

use Moose;
use namespace::autoclean;

BEGIN {extends 'fingerbank::Base::Schema::CombinationMatch'; }


1;
