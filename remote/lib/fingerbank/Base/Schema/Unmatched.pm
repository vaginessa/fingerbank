package fingerbank::Base::Schema::Unmatched;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('unmatched');
__PACKAGE__->add_columns(
    id,
    query,
    result,
    created_at,
);
__PACKAGE__->set_primary_key('id');


1;
