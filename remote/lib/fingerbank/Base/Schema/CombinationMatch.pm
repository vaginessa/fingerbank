package fingerbank::Base::Schema::CombinationMatch;

use Moose;
use namespace::autoclean;

extends 'fingerbank::Base::Schema';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('combinationmatch');

__PACKAGE__->add_columns(
    "id",
    "score",
    "dhcp_fingerprint_id",
    "dhcp6_fingerprint_id",
    "dhcp_vendor_id",
    "dhcp6_enterprise_id",
    "user_agent_id",
    "mac_vendor_id",
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition("
    SELECT * FROM combination
    WHERE dhcp_fingerprint_id = ? OR dhcp6_fingerprint_id = ? OR dhcp_vendor_id = ? OR dhcp6_enterprise_id = ? OR user_agent_id = ? OR (mac_vendor_id = ? OR mac_vendor_id IS NULL)
    ORDER BY
    case when (dhcp_fingerprint_id = ? AND dhcp_fingerprint_id != '0') then 2 else 0 END +
    case when (dhcp6_fingerprint_id = ? AND dhcp6_fingerprint_id != '0') then 2 else 0 END +
    case when (dhcp_vendor_id = ? AND dhcp_vendor_id != '0') then 2 else 0 END +
    case when (dhcp6_enterprise_id = ? AND dhcp6_enterprise_id != '0') then 2 else 0 END +
    case when (user_agent_id = ? AND user_agent_id != '0') then 2 else 0 END +
    case when (mac_vendor_id = ? OR (mac_vendor_id IS NULL AND ? IS NULL)) then 1 else 0 END
    DESC,
    score DESC LIMIT 1
");

__PACKAGE__->meta->make_immutable;

1;
