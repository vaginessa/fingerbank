package fingerbank::Base::CRUD;

use Moose;
use namespace::autoclean;
use POSIX;

use fingerbank::DB;
use fingerbank::Error qw(is_error is_success);
use fingerbank::Log qw(get_logger);


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

=head2 _getTableID

=cut
sub _getTableID {
    my ( $self, $table ) = @_;

    my $db = fingerbank::DB->connect('Local');
    my $resultset = $db->resultset('TablesIDs')->first;

    $table = lc($table);
    return $resultset->$table;
}

=head2 _incrementTableID

=cut
sub _incrementTableID {
    my ( $self, $table ) = @_;

    my $db = fingerbank::DB->connect('Local');

    # Get current ID before incrementing it
    my $resultset = $db->resultset('TablesIDs')->first;
    $table = lc($table);
    my $id = $resultset->$table;

    # Increment the ID and update the table
    $id ++;
    $db->resultset('TablesIDs')->update({ $table => $id });
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

=head2 create

=cut
sub create {
    my ( $self, $args ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    my $entry_id = "L" . $self->_getTableID($className);    # Local entries IDs are prefixed by L

    # Prepare arguments for entry creation
    $args->{id} = $entry_id;    # We need to override the ID for a local one
    $args->{created_at} = strftime("%Y-%m-%d %H:%M:%S", localtime(time));   # Overriding created_at with current timestamp
    $args->{updated_at} = strftime("%Y-%m-%d %H:%M:%S", localtime(time));   # Overriding updated_at with current timestamp

    my $db = fingerbank::DB->connect('Local');
    my $resultset = $db->resultset($className)->create($args);

    # Query doesn't returned any result
    if ( !defined($resultset) ) {
        my $status_msg = "Cannot create new '$className' entry with ID '$entry_id' in schema 'Local'.";
        $logger->info($status_msg);
        return ( $STATUS::INTERNAL_SERVER_ERROR, $status_msg );
    }

    # Increment table ID after successful creation
    $self->_incrementTableID($className);

    # Building the newly created resultset to be returned
    foreach my $column ( $resultset->result_source->columns ) {
        $return->{$column} = $resultset->$column;
    }

    return ( $STATUS::OK, $return );
}

=head2 update

=cut
sub update {
    my ( $self, $id, $args ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

    # We need to update the 'updated_at' timestamp
    $args->{updated_at} = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

    # Fetching current data to build the resultset from which we will then update with new data
    my $db = fingerbank::DB->connect('Local');
    my $resultset = $db->resultset($className)->find($id);

    # Query doesn't returned any result
    if ( !defined($resultset) ) {
        my $status_msg = "Could not find ID '$id' for '$className' in schema 'Local'. Cannot update.";
        $logger->info($status_msg);
        return ( $STATUS::NOT_FOUND, $status_msg );
    }

    # Calling update on the resultset to update it with new data
    $logger->info("Found result in schema 'Local' for '$className' ID '$id'. Updating it.");
    $resultset->update($args);

    # Building the updated resultset to be returned
    foreach my $column ( $resultset->result_source->columns ) {
        $return->{$column} = $resultset->$column;
    }

    return ( $STATUS::OK, $return );
}

=head2 delete

=cut
sub delete {
    my ( $self, $id ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;

    # Fetching current data to build the resultset from which we will delete
    my $db = fingerbank::DB->connect('Local');
    my $resultset = $db->resultset($className)->find($id);

    # Query doesn't returned any result
    if ( !defined($resultset) ) {
        my $status_msg = "Could not find ID '$id' for '$className' in schema 'Local'. Cannot delete.";
        $logger->info($status_msg);
        return ( $STATUS::NOT_FOUND, $status_msg );
    }

    # Calling delete on the resultset to delete it from the database
    $logger->info("Found result in schema 'Local' for '$className' ID '$id'. Deleting it.");
    $resultset->delete;

    return $STATUS::OK;
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
