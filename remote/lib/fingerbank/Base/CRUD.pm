package fingerbank::Base::CRUD;

use Moose;
use namespace::autoclean;

use fingerbank::DB;
use fingerbank::Error qw(is_error is_success);
use fingerbank::Log qw(get_logger);

#has 'id'        => (is => 'rw', isa => 'Str', default => "");
#has 'content'   => (is => 'rw', isa => 'Str', default => "");

=head1 HELPERS

Helper methods used in this class and the inherited ones

=cut

=head1 _parseClassName

Parse the class name based on the caller package name

=cut
sub _parseClassName {
    my ( $self ) = @_;

    my $className = $self;
    $className =~ s#^.*:##;

    return $className;
}


=head1 METHODS

=cut

=head2 read

=cut
sub read {
    my ( $self, $id ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    # If an ID is specified, we are returning the detailled result for that specific ID (read)
    if ( defined($id) ) {
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
            return ( $STATUS::NOT_FOUND, $status_msg );
        }

        $logger->info("Found result in schema '$schema' for '$className' ID '$id'");
        # Building the resultset to be returned
        foreach my $column ( $resultset->result_source->columns ) {
            $return->{$column} = $resultset->$column;
        }

        return ( $STATUS::OK, $return );
    }

    # If no ID is specified, we are returning a list of all the entries (list)
    else {
        foreach my $schema ( @fingerbank::DB::schemas ) {
            $logger->debug("Listing all '$className' entries in schema '$schema'");

            my $db = fingerbank::DB->connect($schema);
            my $resultset = $db->resultset($className)->search;

            # Query doesn't return any result
            if ( $resultset eq 0 ) {
                $logger->info("Listing of '$className' entries in schema '$schema' returned an empty set");
                next;
            }

            $logger->info("Found entries in schema '$schema' for '$className' listing");

            # Building the resultset to be returned
            while ( my $row = $resultset->next ) {
                $return->{$row->id} = $row->value;
            }
        }

        # Query doesn't return any result on any of the schema(s)
        if ( !%$return ) {
            my $status_msg = "Listing of '$className' entries in schema(s) returned an empty set";
            $logger->info($status_msg);
            return ( $STATUS::NOT_FOUND, $status_msg );
        }

        return ( $STATUS::OK, $return );
    }
}

=head2 search

=cut
sub search {
    my ( $self, $query ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    $logger->debug("Searching for '" . $className . "' '" . $query->{get_column} . "' with '" . $query->{search_for} . "' '" . $query->{term} . "'");

    my $column = $query->{get_column};
    foreach my $schema ( @fingerbank::DB::schemas )  {
        $logger->debug("Searching in schema $schema");

        my $db = fingerbank::DB->connect($schema);
        my $resultset = $db->resultset($className)->search({
            $query->{search_for} => $query->{term},
        })->first;

        # Check if resultset contains data
        if ( defined($resultset) ) {
            $return = $resultset->$column;
            $logger->info("Found a match ($column = $return) for $className " . $query->{search_for} . " '" . $query->{term} . "' in schema $schema");
            return ( $STATUS::OK, $return );
        }

        $logger->debug("No match found in schema $schema");
    }

    my $status_msg = "No match found in schema(s) for '" . $className . "' '" . $query->{get_column} . "' with '" . $query->{search_for} . "' '" . $query->{term} . "'";
    $logger->warn($status_msg);
    return ( $STATUS::NOT_FOUND, $status_msg );
}


__PACKAGE__->meta->make_immutable;


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

1;
