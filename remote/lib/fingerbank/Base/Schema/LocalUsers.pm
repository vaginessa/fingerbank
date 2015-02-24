package fingerbank::Base::Schema::LocalUsers;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    "id",
    "username",
    "password",
    "encryption",
    "firstname",
    "lastname",
    "email",
    "notes",
    "created_at",
    "updated_at",
    "created_by",
);
__PACKAGE__->set_primary_key('id');


1;
