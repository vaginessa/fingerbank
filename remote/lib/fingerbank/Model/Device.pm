package fingerbank::Model::Device;

=head1 NAME

fingerbank::Model::Device

=head1 DESCRIPTION

Handling 'Device' related stuff

=cut

use Moose;
use namespace::autoclean;

use fingerbank::Log qw(get_logger);

extends 'fingerbank::Base::CRUD';


=head2 read

=cut
sub read {
    my ( $self, $id, $with_parents) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    # Verify if the provided ID is part of the local or upstream schema to seach accordingly
    # Local schema IDs are 'L' prefixed
    my $schema = ( lc($id) =~ /^l/ ) ? 'Local' : 'Upstream';

    $logger->debug("Looking for '$className' ID '$id' in schema '$schema'");

    my $db = fingerbank::DB->connect($schema);
    my $resultset = $db->resultset($className)->find($id);

    # Query doesn't return any result
    if ( !defined($resultset) ) {
        my $status_msg = "Could not find ID '$id' in '$className' in schema '$schema'";
        $logger->info($status_msg);
        return ( $fingerbank::Status::NOT_FOUND, $status_msg );
    }

    $logger->info("Found result in schema '$schema' for '$className' ID '$id'");

    # Building the resultset to be returned
    foreach my $column ( $resultset->result_source->columns ) {
        $return->{$column} = $resultset->$column;
    }

    # If parents are requested, we build them
    if ( defined($with_parents) ) {
        if ( defined($return->{parent_id}) ) {
            my $parent_exists = 1;
            my $parent_id = $return->{parent_id};
            my @parents;
            my $iteration = 0;
            while ( $parent_exists ) {
                my $parent = $self->read($parent_id);
                foreach my $key ( keys %$parent ) {
                    $parents[$iteration]{$key} = $parent->{$key};
                }
                $iteration ++;
                $parent_id = $parent->{parent_id} if ( defined($parent->{parent_id}) );
                $parent_exists = 0 if ( !defined($parent->{parent_id}) );
            }
            $return->{parents} = \@parents;
        }
    }

    return ( $fingerbank::Status::OK, $return );
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;

1;
