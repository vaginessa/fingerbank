package fingerbank::Log;

=head1 NAME

fingerbank::Log

=head1 DESCRIPTION

Logging framework that will take care of returning a logging instance depending on caller and
will also handle the initiation and watching of log configuration files.

=cut

use strict;
use warnings;

use Log::Log4perl;

use fingerbank::FilePaths;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(init_logger get_logger);
}

# Initiate the logger and check config every 10 seconds in case level changes
sub init_logger {
    Log::Log4perl::init_and_watch($LOG_CONF_FILE, 10);
}

=head1 METHODS

=cut

=head2 get_logger

Return a logger instance for the caller package

=cut
sub get_logger {
    my ( $package, $filename, $line ) = caller;
    return Log::Log4perl->get_logger($package);
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
