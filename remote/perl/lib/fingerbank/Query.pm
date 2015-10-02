package fingerbank::Query;

use Moose;
use namespace::autoclean;

use JSON;
use LWP::UserAgent;
use Module::Load;
use POSIX;

use fingerbank::Config;
use fingerbank::Constant qw($TRUE);
use fingerbank::Log;
use fingerbank::Model::Combination;
use fingerbank::Model::Device;
use fingerbank::Util qw(is_enabled is_disabled is_error is_success);
use fingerbank::Discoverers;
use fingerbank::Discoverers::LocalDB;
use fingerbank::Discoverers::API;
use fingerbank::Discoverers::TCPFingerprinting;

=head2 match

=cut

sub match {
    my ( $self, $args ) = @_;
    my $logger = fingerbank::Log::get_logger;
    my $discoverers = fingerbank::Discoverers->new;
    $discoverers->register_discoverer(fingerbank::Discoverers::LocalDB->new);
    $discoverers->register_discoverer(fingerbank::Discoverers::API->new);
    $discoverers->register_discoverer(fingerbank::Discoverers::TCPFingerprinting->new);

    return $discoverers->match_best($args);
}

=head2 isWindows

Test if device (name or ID) is Windows based

=cut

sub isWindows {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $WINDOWS_PARENT_ID = 1;
    $logger->debug("Testing if device '$device' is a Windows based device");

    my $result = fingerbank::Model::Device->is_a($device, $WINDOWS_PARENT_ID);

    $logger->debug("Device '$device' is a Windows based device") if $result;

    return $result;
}

=head2 isMacOS

Test if device (name or ID) is MacOS based

=cut

sub isMacOS {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $MACOS_PARENT_ID = 2;
    $logger->debug("Testing if device '$device' is a MacOS based device");

    my $result = fingerbank::Model::Device->is_a($device, $MACOS_PARENT_ID);

    $logger->debug("Device '$device' is a MacOS based device") if $result;

    return $result;
}

=head2 isAndroid

Test if device (name or ID) is Android based

=cut

sub isAndroid {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $ANDROID_PARENT_ID = 202;
    $logger->debug("Testing if device '$device' is an Android based device");

    my $result = fingerbank::Model::Device->is_a($device, $ANDROID_PARENT_ID);

    $logger->debug("Device '$device' is an Android based device") if $result;

    return $result;
}

=head2 isIOS

Test if device (name or ID) is IOS based

=cut

sub isIOS {
    my ( $self, $device ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $IOS_PARENT_ID = 193;
    $logger->debug("Testing if device '$device' is an IOS based device");

    my $result = fingerbank::Model::Device->is_a($device, $IOS_PARENT_ID);

    $logger->debug("Device '$device' is an IOS based device") if $result;

    return $result;
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
