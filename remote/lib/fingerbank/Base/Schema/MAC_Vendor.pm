package fingerbank::Base::Schema::MAC_Vendor;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('mac_vendor');
__PACKAGE__->add_columns(
    id,
    name,
    mac,
    created_at,
    updated_at,
);
__PACKAGE__->set_primary_key('id');

# Custom accessor (value) that returns the MAC_Vendor name in list context
sub value {
    my ( $self ) = @_;
    return $self->name;
}

1;
