package fingerbank::Util;

=head1 NAME

fingerbank::Util

=head1 DESCRIPTION

Methods that helps simplify code reading

=cut

use strict;
use warnings;

use fingerbank::Constant qw($TRUE $FALSE);

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(
        is_enabled 
        is_disabled
        is_success
        is_error
    );
}

=head1 METHODS

=head2 is_enabled

Is the given configuration parameter considered enabled? y, yes, true, enable, enabled and 1 are all positive values

=cut

sub is_enabled {
    my ($enabled) = @_;
    if ( $enabled && $enabled =~ /^\s*(y|yes|true|enable|enabled|1)\s*$/i ) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}

=head2 is_disabled

Is the given configuration parameter considered disabled? n, no, false, disable, disabled and 0 are all negative values

=cut

sub is_disabled {
    my ($disabled) = @_;
    if ( !defined ($disabled) || $disabled =~ /^\s*(n|no|false|disable|disabled|0)\s*$/i ) {
        return $TRUE;
    } else {
        return $FALSE;
    }
}

=head2 is_success

Returns a true or false value based on if given error code is considered a success or not.

=cut

sub is_success {
    my ($code) = @_;
    return $TRUE if ($code >= 200 && $code < 300);
    return $FALSE;
}

=head2 is_error

Returns a true or false value based on if given error code is considered an error or not.

=cut

sub is_error {
    my ($code) = @_;
    return $TRUE if ($code >= 400 && $code < 600);
    return $FALSE;
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
