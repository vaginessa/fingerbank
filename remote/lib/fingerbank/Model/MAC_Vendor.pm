package fingerbank::Model::MAC_Vendor;

=head1 NAME

fingerbank::Model::MAC_Vendor

=head1 DESCRIPTION

Handling 'MAC_Vendor' related stuff

=cut

use Moose;
use namespace::autoclean;

use fingerbank::DB;
use fingerbank::Error qw(is_error is_success);
use fingerbank::Log qw(get_logger);

extends 'fingerbank::Base::CRUD';


=head1 METHODS

=cut

=head2 search

=cut
sub search {
    my ( $self, $query ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    # We need to modify the MAC format before the search to make sure it fits what we have in database
    my $mac = $query->{term};
    $mac =~ s/[:|\s|-]//g;      # Removing separators
    $mac = lc($mac);            # Lowercasing
    $mac = substr($mac, 0, 6);  # Only keep first 6 characters (OUI)

    # Updating the query
    $query->{search_for} = 'mac'; # MAC_Vendor table is different from the others. The 'value' column is the 'mac' column in this specific case
    $query->{term} = $mac;        # Using the 'sanitized' MAC as search term

    $logger->debug("Searching for '" . $className . "' '" . $query->{get_column} . "' with '" . $query->{search_for} . "' '" . $query->{term} . "'");

    if ( $query->{term} eq '' ) {
        $logger->debug("$className " . $query->{search_for} . " is empty. This is a special case and we are returning 'NULL' as " . $query->{get_column});
        return ( $fingerbank::Status::OK, 'NULL' );
    }

    my $column = $query->{get_column};
    foreach my $schema ( @fingerbank::DB::schemas )  {
        $logger->debug("Searching in schema $schema");

        my $db = fingerbank::DB->connect($schema);
        my $resultset = $db->resultset($className)->search({
            $query->{search_for} => $query->{term},
        });

        # Check if resultset contains data
        if ( defined($resultset->first) ) {
            $return = $resultset->first->$column;
            $logger->info("Found a match ($column = $return) for $className " . $query->{search_for} . " '" . $query->{term} . "' in schema $schema");
            return ( $fingerbank::Status::OK, $return );
        }

        $logger->debug("No match found in schema $schema");
    }

    my $status_msg = "No match found in schema(s) for '" . $className . "' '" . $query->{get_column} . "' with '" . $query->{search_for} . "' '" . $query->{term} . "'";
    $logger->warn($status_msg);
    return ( $fingerbank::Status::NOT_FOUND, $status_msg );
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
