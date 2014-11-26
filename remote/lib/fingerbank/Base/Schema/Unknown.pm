package fingerbank::Base::Schema::Unknown;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('unknown');
__PACKAGE__->add_columns(
    id,
    type,
    value,
    created_at,
);
__PACKAGE__->set_primary_key('id');


1;
