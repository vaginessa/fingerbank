package fingerbank::DB;

use strict;
use warnings;

use LWP::Simple qw(getstore);    # Required in fetch_upstream (getstore)

use fingerbank::Config qw(%Config);
use fingerbank::Error qw(is_error is_success);
use fingerbank::FilePaths qw($INSTALL_PATH);
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
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    if ( !defined($Config{'upstream'}{'api_key'}) || $Config{'upstream'}{'api_key'} eq "" ) {
        $logger->warn("Can't communicate with upstream without a valid API key.");
        return;
    }

    my $database_file = $INSTALL_PATH . "db/fingerbank_Upstream.db";
    my $download_url = $Config{'upstream'}{'db_url'} . $Config{'upstream'}{'api_key'};

    $logger->info("Downloading the latest version of upstream database from '$download_url'");

    my $status = getstore($download_url, $database_file);

    $logger->warn("Failed to download latest version of upstream database with the following return code: $status") if is_error($status);
}

=head2 initialize_local

Create with the appropriate schema, the local version of the Fingerbank database

Will also make sure a local instance doesn't already exists.

=cut
sub initialize_local {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $database_file   = $INSTALL_PATH . "db/fingerbank_Local.db";
    my $schema_file     = $INSTALL_PATH . "db/schema_Local.sql";

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
