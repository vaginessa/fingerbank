package fingerbank::Config;

=head1 NAME

fingerbank::Config

=head1 DESCRIPTION

Reading and writing configuration parameters

=cut

use strict;
use warnings;

use Config::IniFiles;

use fingerbank::Constants qw($TRUE $FALSE);
use fingerbank::FilePaths qw($DEFAULT_CONF_FILE $CONF_FILE);
use fingerbank::Log;

our %Config;

=head2 read_config

Read content of flat file into the config hash

=cut

sub read_config {
    my $logger = fingerbank::Log::get_logger;

    if ( ! -e $DEFAULT_CONF_FILE ) {
        $logger->warn("Fingerbank default configuration file '$DEFAULT_CONF_FILE' has not been found. Cannot continue");
        return;
    }

    # If a configuration file exists, load the defaults and override using the existing configuration file
    # We allow empty file in the case a 'fingerbank.conf' file is modified to reflect all the defaults parameters (which will lead to an empty 'fingerbank.conf' file) and that file is not being deleted.
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

=head2 write_config

Write content of config hash to flat file

=cut

sub write_config {
    my $logger = fingerbank::Log::get_logger;

    # Loading the defaults to compare and delete configuration parameters that are equals to their defaults.
    my %defaultConfig;
    tie %defaultConfig, 'Config::IniFiles', (
        -import => Config::IniFiles->new( -file => $DEFAULT_CONF_FILE )
    ) or die "Invalid Fingerbank default configuration file: $!\n";
    $logger->debug("Loading default configuration to compare before write.");

    # Sanitizing before writing
    $logger->debug("Sanitizing configuration hash before writing it");
    foreach my $section ( tied(%Config)->Sections ) {
        # Delete keys equals to their defaults
        next if ( !exists($defaultConfig{$section}) );
        foreach my $key ( keys(%{$defaultConfig{$section}}) ) {
            next if ( !exists($defaultConfig{$section}{$key}) );
            if ( $Config{$section}{$key} eq $defaultConfig{$section}{$key} ) {
                $logger->debug("'$section'-'$key' is equals to it's default value. Removing it before write");
                $logger->debug("Defaut: {$section}{$key}=" . $defaultConfig{$section}{$key});
                $logger->debug("Config: {$section}{$key}=" . $Config{$section}{$key});
                delete $Config{$section}{$key};
                tied(%Config)->DeleteParameterComment($section, $key);
            }
        }

        # Delete empty sections
        if ( scalar(keys(%{$Config{$section}})) == 0 ) {
            $logger->debug("'$section' is empty after sanitization. Removing it before write");
            delete $Config{$section};
        }
    }

    # Writing the config hash to flat file
    tied(%Config)->WriteConfig($CONF_FILE) or die "Error writing Fingerbank configuration file '$CONF_FILE'";
    $logger->debug("Writing current config hash to file '$CONF_FILE'");
}

=head2 get_config

=cut

sub get_config {
    my ( $section, $parameter ) = @_;
    my $logger = fingerbank::Log::get_logger;

    read_config();

    if ( defined($parameter) && $parameter ne "" ) {
        $logger->debug("Requested Fingerbank configuration parameter '$parameter' of section '$section'");
        return $Config{$section}{$parameter};
    }

    if ( defined($section) && $section ne "" ) {
        $logger->debug("Requested Fingerbank configuration for section '$section'");
        return $Config{$section};
    }

    $logger->debug("Requested Fingerbank configuration");
    return \%Config;
}

=head2 is_api_key_configured

=cut

sub is_api_key_configured {
    my $api_key = get_config('upstream', 'api_key');
    ( defined($api_key) && $api_key ne "" ) ? return $TRUE : return $FALSE;
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
