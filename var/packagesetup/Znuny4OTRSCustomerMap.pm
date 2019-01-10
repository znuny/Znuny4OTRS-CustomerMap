# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::Znuny4OTRSCustomerMap;    ## no critic

use strict;
use warnings;

use utf8;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::SysConfig',
    'Kernel::System::ZnunyHelper',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

var::packagesetup::Znuny4OTRSCustomerMap - code to execute during package installation

=head1 SYNOPSIS

All code to execute during package installation

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $CodeObject    = $Kernel::OM->Get('var::packagesetup::Znuny4OTRSCustomerMap');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    $ZnunyHelperObject->_PackageSetupInit();

    return $Self;
}

=head2 CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=head2 CodeUpgrade507()

run the code upgrade part for versions below 5.0.7

    my $Result = $CodeObject->CodeUpgrade507();

=cut

sub CodeUpgrade507 {
    my ( $Self, %Param ) = @_;

    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    my $DashboardBackendConfig = $ConfigObject->Get('DashboardBackend');

    my $MapsURL = $DashboardBackendConfig->{'0001-CustomerMap'}->{MapsURL};

    if ( $MapsURL =~ /\?key=(.+)/i ) {

        my $GoogleAPIKey = $1;

        return 1 if !$GoogleAPIKey;

        $ConfigObject->Set(
            Key   => 'Znuny4OTRS::CustomerMap::GoogleAPIKey',
            Value => $GoogleAPIKey,
        );

        my $Result = $SysConfigObject->SettingsSet(
            Settings => [
                {
                    Name           => 'Znuny4OTRS::CustomerMap::GoogleAPIKey',
                    IsValid        => 1,
                    EffectiveValue => $GoogleAPIKey,
                },
            ],
            UserID => 1,
        );

        my $SettingName = 'DashboardBackend###0001-CustomerMap';

        my $GUID = $SysConfigObject->SettingLock(
            Name   => $SettingName,
            UserID => 1,
            Force  => 1,
        );

        $Result = $SysConfigObject->SettingReset(
            Name              => $SettingName,
            ExclusiveLockGUID => $GUID,
            UserID            => 1,
        );

        $Result = $SysConfigObject->SettingUnlock(
            Name => $SettingName,
        );

    }

    return 1;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut