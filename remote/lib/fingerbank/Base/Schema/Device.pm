package fingerbank::Base::Schema::Device;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('device');
__PACKAGE__->add_columns(
    id,
    name,
    mobile,
    tablet,
    created_at,
    updated_at,
    parent_id,
    inherit,
    submitter_id,
    approved,
);
__PACKAGE__->set_primary_key('id');

=item value

=cut
sub value {
    my ( $self ) = @_;
    return $self->name;
}

1;
