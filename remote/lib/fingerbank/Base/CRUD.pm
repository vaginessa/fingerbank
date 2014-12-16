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
        return ( $fingerbank::Status::INTERNAL_SERVER_ERROR, $status_msg );
    }

    # Increment table ID after successful creation
    $self->_incrementTableID($className);

    # Building the newly created resultset to be returned
    foreach my $column ( $resultset->result_source->columns ) {
        $return->{$column} = $resultset->$column;
    }

    return ( $fingerbank::Status::OK, $return );
}

=head2 read

=cut
sub read {
    my ( $self, $id ) = @_;
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

    return ( $fingerbank::Status::OK, $return );
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
        return ( $fingerbank::Status::NOT_FOUND, $status_msg );
    }

    # Calling update on the resultset to update it with new data
    $logger->info("Found result in schema 'Local' for '$className' ID '$id'. Updating it.");
    $resultset->update($args);

    # Building the updated resultset to be returned
    foreach my $column ( $resultset->result_source->columns ) {
        $return->{$column} = $resultset->$column;
    }

    return ( $fingerbank::Status::OK, $return );
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
        return ( $fingerbank::Status::NOT_FOUND, $status_msg );
    }

    # Calling delete on the resultset to delete it from the database
    $logger->info("Found result in schema 'Local' for '$className' ID '$id'. Deleting it.");
    $resultset->delete;

    return $fingerbank::Status::OK;
}

=head2 list

=cut
sub list {
    my ( $self ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $return = {};

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
        return ( $fingerbank::Status::NOT_FOUND, $status_msg );
    }

    return ( $fingerbank::Status::OK, $return );
}

=head2 list_paginated

Handing out a parameterized list of results.

Query optionnal parameters:

- offset: Where to being the listing from (I want 10 result starting after the sixth one). Don't forget that DBIx offset is zero based.

- nb_of_rows: The number of results

- order: asc or desc

- order_by: The field on which we should order the results

- schema: From which schema we want the results. Either 'Upstream' or 'Local'. Default to all

=cut
sub list_paginated {
    my ( $self, $query ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my @return;

    # From which schema do we want the results
    my @schemas = ( defined($query->{schema}) ) ? ($query->{schema}) : @fingerbank::DB::schemas;

    foreach my $schema ( @schemas ) {
        $logger->debug("Listing all '$className' entries in schema '$schema'");

        my $db = fingerbank::DB->connect($schema);
        my $resultset = $db->resultset($className)->search({},
            { offset => $query->{offset}, rows => $query->{nb_of_rows}, order_by => { -$query->{order} => $query->{order_by} } }
        );

        # Query doesn't returned any result
        if ( $resultset eq 0 ) {
            $logger->info("Listing of '$className' entries in schema '$schema' returned an empty set");
            next;
        }

        $logger->info("Found entries in schema '$schema' for '$className' listing");

        # Building the resultset to be returned
        while ( my $row = $resultset->next ) {
            my %array_row = ( 'id' => $row->id, 'value' => $row->value );
            push ( @return, \%array_row );
        }
    }

    return @return;
}

=head2 count

=cut
sub count {
    my ( $self, $schema ) = @_;
    my $logger = get_logger;

    my $className = $self->_parseClassName;
    my $count;

    # From which schema do we want the results
    my @schemas = ( defined($schema) ) ? ($schema) : @fingerbank::DB::schemas;

    foreach my $schema ( @schemas ) {
        my $db = fingerbank::DB->connect($schema);
        my $nb_of_rows = $db->resultset($className)->search->count;
        $count += $nb_of_rows;
    }

    return $count;
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
