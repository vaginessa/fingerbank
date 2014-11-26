package fingerbank::Schema::Local;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(
    Combination,
    CombinationMatch,
    Device,
    DHCP_Fingerprint,
    DHCP_Vendor,
    MAC_Vendor,
    User_Agent,
    Unknown,
    Unmatched,
    TablesIDs,
);


1;
