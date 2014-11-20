package fingerbank::Base::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Combination CombinationMatch Device DHCP_Fingerprint DHCP_Vendor MAC_Vendor User_Agent/);

1;
