package fingerbank::Base::Schema::User_Agent;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('user_agent');
__PACKAGE__->add_columns(
    id,
    value,
    created_at,
    updated_at,
);
__PACKAGE__->set_primary_key('id');

1;
