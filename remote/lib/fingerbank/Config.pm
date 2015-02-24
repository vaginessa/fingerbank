package fingerbank::Config;

=head1 NAME

fingerbank::Config

=head1 DESCRIPTION

File paths and configuration parameters

=cut

use strict;
use warnings;

use Config::IniFiles;
use Readonly;

use fingerbank::FilePaths;
use fingerbank::Log qw(get_logger);

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(%Config);
}

# MAKE IT SINGLETON ?
our %Config;

read_config();

sub read_config {
    my $logger = get_logger;

    if ( ! -e $DEFAULT_CONF_FILE ) {
        $logger->warn("Fingerbank default configuration file '$DEFAULT_CONF_FILE' has not been found. Cannot continue");
        return;
    }

    # If a configuration file exists, load both the defaults and override using the existing configuration file
    # We allow empty file in the case a fingerbank.conf file is modified to reflect all the defaults parameters (which will lead to an empty fingerbank.conf file) and that file has not been deleted.
    if ( (-e $DEFAULT_CONF_FILE) && (-e $CONF_FILE) ) {
        tie %Config, 'Config::IniFiles', (
            -file       => $CONF_FILE,
            -import     => Config::IniFiles->new( -file => $DEFAULT_CONF_FILE ),
            -allowempty => 1,
        ) or die "Invalid Fingerbank configuration file: $!\n";
        $logger->debug("Existing Fingerbank configuration file. Loading it with defaults");
    }

    # No configuration file found. Loading the defaults
    # SetFileName allow the saving of the tied hash later with the accurate file name
    else {
        tie %Config, 'Config::IniFiles', ( 
            -import => Config::IniFiles->new( -file => $DEFAULT_CONF_FILE )
        ) or die "Invalid Fingerbank default configuration file: $!\n";
        tied(%Config)->SetFileName($CONF_FILE);
        $logger->debug("No existing Fingerbank configuration file. Loading defaults");
    }
}


=back

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
