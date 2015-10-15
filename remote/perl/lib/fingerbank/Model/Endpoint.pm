package fingerbank::Model::Endpoint;

=head1 NAME

fingerbank::Model::Endpoint

=head1 DESCRIPTION

Class that represents an endpoint

=cut

use Moose;
use namespace::autoclean;

use fingerbank::Constant qw($TRUE $FALSE);
use fingerbank::Log;
use fingerbank::Util qw(is_error is_success);
use fingerbank::Model::Device;
use List::MoreUtils qw(any);

has 'name' => (is => 'rw', required => 1);
has 'version' => (is => 'rw', required => 1);
has 'score' => (is => 'rw', required => 1);
has 'parents' => (is => 'rw', isa => 'ArrayRef', default => sub {[]});

=head2 fromResult

=cut

sub fromResult {
    my ( $class, $result ) = @_;
    my @parents;
    foreach my $parent (@{$result->{device}->{parents}}){
        push @parents, $parent->{name};
    }
    return $class->new(name => $result->{device}->{name}, version => $result->{version}, score => $result->{score}, parents => \@parents);
}

=head2 isWindows

Test if device (name or ID) is Windows based

=cut

sub isWindows {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $WINDOWS_PARENT_ID = 1;
    $logger->debug("Testing if device '".$self->name."' is a Windows based device");

    my ($status, $parent) = fingerbank::Model::Device->read($WINDOWS_PARENT_ID);

    my $result = $self->isa($parent->{name});

    $logger->debug("Device '".$self->name."' is a Windows based device") if $result;

    return $result;
}

=head2 isMacOS

Test if device (name or ID) is MacOS based

=cut

sub isMacOS {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $MACOS_PARENT_ID = 2;
    $logger->debug("Testing if device '".$self->name."' is a MacOS based device");

    my ($status, $parent) = fingerbank::Model::Device->read($MACOS_PARENT_ID);

    my $result = $self->isa($parent->{name});

    $logger->debug("Device '".$self->name."' is a MacOS based device") if $result;

    return $result;
}

=head2 isAndroid

Test if device (name or ID) is Android based

=cut

sub isAndroid {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $ANDROID_PARENT_ID = 202;
    $logger->debug("Testing if device '".$self->name."' is a Android based device");

    my ($status, $parent) = fingerbank::Model::Device->read($ANDROID_PARENT_ID);

    my $result = $self->isa($parent->{name});

    $logger->debug("Device '".$self->name."' is a Android based device") if $result;

    return $result;
}

=head2 isIOS

Test if device (name or ID) is IOS based

=cut

sub isIOS {
    my ( $self ) = @_;
    my $logger = fingerbank::Log::get_logger;

    my $IOS_PARENT_ID = 193;
    $logger->debug("Testing if device '".$self->name."' is a IOS based device");

    my ($status, $parent) = fingerbank::Model::Device->read($IOS_PARENT_ID);

    my $result = $self->isa($parent->{name});

    $logger->debug("Device '".$self->name."' is a IOS based device") if $result;

    return $result;
}


=head2 isa

=cut

sub isa {
    my ( $self, $device_name ) = @_;
    my $logger = fingerbank::Log::get_logger;
    return $self->name eq $device_name || $self->hasParent($device_name);
}

=head2 hasParent

=cut

sub hasParent {
    my ( $self, $device_name ) = @_;
    return any { $_ eq $device_name } @{$self->parents};
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

__PACKAGE__->meta->make_immutable;

1;
