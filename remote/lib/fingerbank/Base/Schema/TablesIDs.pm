package fingerbank::Base::Schema::TablesIDs;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('tables_ids');
__PACKAGE__->add_columns(
    combination,
    device,
    dhcp_fingerprint,
    dhcp_vendor,
    mac_vendor,
    user_agent,
);


1;
