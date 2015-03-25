package fingerbank::FilePaths;

=head1 NAME

fingerbank::FilePaths

=head1 DESCRIPTION

File paths and static parameters

=cut

use strict;
use warnings;

use File::Spec::Functions;
use Readonly;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(
        $INSTALL_PATH
        $CONF_FILE
        $DEFAULT_CONF_FILE
        $LOG_CONF_FILE
        $LOG_FILE
    );
}

Readonly::Scalar our $INSTALL_PATH          => '/usr/local/fingerbank/';
Readonly::Scalar our $CONF_FILE             => catfile($INSTALL_PATH, 'conf/fingerbank.conf');
Readonly::Scalar our $DEFAULT_CONF_FILE     => catfile($INSTALL_PATH, 'conf/fingerbank.conf.defaults');
Readonly::Scalar our $LOG_CONF_FILE         => catfile($INSTALL_PATH, 'conf/log.conf');
Readonly::Scalar our $LOG_FILE              => catfile($INSTALL_PATH, 'logs/fingerbank.log');

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
