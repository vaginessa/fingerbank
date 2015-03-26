package fingerbank::DB;

=head1 NAME

fingerbank::DB

=head1 DESCRIPTION

Databases related interaction class

=cut

use strict;
use warnings;

use File::Copy;
use LWP::Simple qw(getstore);
use POSIX qw(strftime);

use fingerbank::Config;
use fingerbank::Constants qw($TRUE);
use fingerbank::Error qw(is_error is_success);
use fingerbank::FilePaths qw($INSTALL_PATH $LOCAL_DB_FILE $LOCAL_DB_SCHEMA $UPSTREAM_DB_FILE);
use fingerbank::Log;
use fingerbank::Schema::Local;
use fingerbank::Schema::Upstream;

our @schemas = ('Local', 'Upstream');

sub connect {
    my ( $self, $schema ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $status_msg;
    $logger->debug("Requested connection to database schema '$schema'");

    # Check if the requested schema is a valid one
    my %schemas = map { $_ => 1 } @schemas;
    if ( !exists($schemas{$schema}) ) {
        $logger->warn("Requested schema '$schema' does not exists");
        return;
    }

    # Establishing connection to the requested database schema
    return "fingerbank::Schema::$schema"->connect("dbi:SQLite:" . $INSTALL_PATH . "db/fingerbank_$schema.db");
}

=head2 fetch_upstream

Download the latest version of the upstream Fingerbank database

=cut

sub fetch_upstream {
    my ( $self, $is_updating ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $Config = fingerbank::Config::get_config;

    if ( !defined($Config->{'upstream'}{'api_key'}) || $Config->{'upstream'}{'api_key'} eq "" ) {
        $logger->warn("Can't communicate with upstream without a valid API key.");
        return;
    }

    my $database_file = $UPSTREAM_DB_FILE;
    $database_file = $database_file . ".new" if ( defined($is_updating) && $is_updating );
    my $download_url = $Config->{'upstream'}{'db_url'} . $Config->{'upstream'}{'api_key'};

    $logger->debug("Downloading the latest version of upstream database from '$download_url' to '$database_file'");

    my $status = getstore($download_url, $database_file);

    $logger->warn("Failed to download latest version of upstream database with the following return code: $status") if is_error($status);

    return $status;
}

=head2 initialize_local

Create with the appropriate schema, the local version of the Fingerbank database

Will also make sure a local instance doesn't already exists.

=cut

sub initialize_local {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $database_file   = $LOCAL_DB_FILE;
    my $schema_file     = $LOCAL_DB_SCHEMA;

    if ( -f $database_file ) {
        $logger->warn("Tried to initialize 'Local' database by applying default schema on an existing database. Exiting");
        return;
    }

    $logger->debug("Initializing 'Local' database by applying default schema");
    system("sqlite3 $database_file < $schema_file");
    if ( $? != 0 ) {
        $logger->warn("Failed to initialize 'Local' database when applying default schema");
        return;
    } else {
        $logger->info("Successfully initialized 'Local' database by applying default schema");
    }
}

=head2

=cut

sub update_upstream {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my ( $status, $status_msg );

    my $date                    = POSIX::strftime( "%Y%m%d_%H%M%S", localtime );
    my $database_file           = $UPSTREAM_DB_FILE;
    my $database_file_backup    = $database_file . "_$date";
    my $database_file_new       = $database_file . ".new";

    # Fetching the latest version of upstream database from Fingerbank project
    # $TRUE is for "we are updating". See fingerbank::DB::fetch_upstream
    my $is_an_update = $TRUE;
    $status = fetch_upstream($self, $is_an_update);

    if ( is_success($status) ) {
        # We create a backup of the actual upstream database file
        $logger->debug("Backing up actual 'upstream' database file to '$database_file_backup'");
        copy($database_file, $database_file_backup);

        # We move the newly downloaded upstream database file to the existing one
        $logger->debug("Moving new 'upstream' database file to existing one");
        move($database_file_new, $database_file);

        $status_msg = "Successfully updated Fingerbank 'upstream' database file";
        $logger->info($status_msg);

        return ( $status, $status_msg );
    }

    $status_msg = "An error occured while updating Fingerbank 'upstream' database file";
    $logger->warn($status_msg);

    return ( $status, $status_msg )
}

=head2

=cut

sub submit_unknown {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my ( $status, $status_msg );

    $status = $fingerbank::Status::NOT_IMPLEMENTED; 
    $status_msg = "Not yet implemented";
    $logger->debug($status_msg);

    return ( $status, $status_msg );
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

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
