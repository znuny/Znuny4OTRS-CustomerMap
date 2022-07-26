# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Dashboard::CustomerMap;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{PrefKeyShown}    = 'UserDashboardPref' . $Self->{Name} . '-Shown';
    $Self->{PrefKeyShownMax} = 'UserDashboardPref' . $Self->{Name} . '-ShownMax';

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    # disable params
    return;
}

sub Config {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $APIKey = $ConfigObject->Get('Znuny4OTRS::CustomerMap::GoogleAPIKey');
    $Self->{Config}->{MapsURL} .= $APIKey;

    my %Config = (
        %{ $Self->{Config} },
        Link                      => $LayoutObject->{Baselink} . 'Action=AgentCustomerMap',
        LinkTitle                 => 'Detail',
        PreferencesReloadRequired => 1,
    );

    return %Config;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    $LayoutObject->Block(
        Name => 'ContentLargeCustomerMapData',
        Data => {
            %{ $Self->{Config} },
            Name        => $Self->{Name},
            Latitude    => $Self->{UserCustomerMapLatitude} || $Self->{Config}->{DefaultLatitude},
            Longitude   => $Self->{UserCustomerMapLongitude} || $Self->{Config}->{DefaultLongitude},
            Zoom        => $Self->{UserCustomerMapZoom} || $Self->{Config}->{DefaultZoom},
            Width       => '100%',
            Height      => '400px',
            MapLanguage => $LayoutObject->{UserLanguage},
        },
    );

    my $Content = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardCustomerMap',
        Data         => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
        },
    );

    return $Content;
}

1;
