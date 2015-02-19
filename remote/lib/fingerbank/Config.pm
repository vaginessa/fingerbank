package fingerbank::Config;

=head1 NAME

fingerbank::Config

=head1 DESCRIPTION

File paths and configuration parameters

=cut

use strict;
use warnings;

use Readonly;

use fingerbank::FilePaths;

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );
    @ISA = qw(Exporter);
    @EXPORT = qw(
        $INSTALL_PATH $UPSTREAM_DB_URL $UPSTREAM_QUERY_URL $API_KEY
        $QUERY_UPSTREAM $RECORD_UNMATCHED
    );
}


Readonly::Scalar our $UPSTREAM_DB_URL       => 'https://fingerbank.inverse.ca/api/v1/download?key=';
Readonly::Scalar our $UPSTREAM_QUERY_URL    => 'https://fingerbank.inverse.ca/api/v1/combinations/interogate?key=';
Readonly::Scalar our $API_KEY               => '';


# Should we query upstream Fingerbank API if no result found
Readonly::Scalar our $QUERY_UPSTREAM        => '1';

# Should we keep track of the unmatched query keys
Readonly::Scalar our $RECORD_UNMATCHED      => '1';


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
