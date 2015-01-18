package fingerbank::Base::Schema::Combination;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('combination');
__PACKAGE__->add_columns(
    "id",
    "dhcp_fingerprint_id",
    "user_agent_id",
    "created_at",
    "updated_at",
    "device_id",
    "version",
    "dhcp_vendor_id",
    "score",
    "mac_vendor_id",
    "submitter_id",
);
__PACKAGE__->set_primary_key('id');

# Custom accessor (value) that returns the Combination device_id when called for listing entries
# See L<fingerbank::Base::CRUD::read>
sub value {
    my ( $self ) = @_;
    return $self->device_id;
}


package fingerbank::Base::Schema::CombinationMatch;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('combinationmatch');
__PACKAGE__->add_columns(
    "id",
    "score",
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition("
    SELECT * FROM combination
    WHERE dhcp_fingerprint_id = ? OR dhcp_vendor_id = ? OR user_agent_id = ? OR (mac_vendor_id = ? OR mac_vendor_id IS NULL)
    ORDER BY
    case when dhcp_fingerprint_id = ? then 1 else 0 END +
    case when dhcp_vendor_id = ? then 1 else 0 END +
    case when user_agent_id = ? then 1 else 0 END +
    case when (mac_vendor_id = ? OR (mac_vendor_id IS NULL AND ? IS NULL)) then 1 else 0 END
    DESC,
    score DESC LIMIT 1
");


1;
