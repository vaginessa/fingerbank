package fingerbank::Base::Schema::DHCP_Fingerprint;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('dhcp_fingerprint');
__PACKAGE__->add_columns(
   "id",
   "value",
   "created_at",
   "updated_at",
);
__PACKAGE__->set_primary_key('id');


1;
