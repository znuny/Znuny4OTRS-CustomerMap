# --
# Kernel/Output/HTML/DashboardCustomerMap.pm
# Copyright (C) 2001-2011 Martin Edenhofer, http://edenhofer.de/
# Copyright (C) 2012 Znuny GmbH, http://znuny.com/
# --
# $Id: $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::DashboardCustomerMap;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed objects
    for (
        qw(Config Name ConfigObject LogObject DBObject LayoutObject ParamObject TicketObject UserID)
        )
    {
        die "Got no $_!" if ( !$Self->{$_} );
    }

    $Self->{PrefKeyShown}    = 'UserDashboardPref' . $Self->{Name} . '-Shown';
    $Self->{PrefKeyShownMax} = 'UserDashboardPref' . $Self->{Name} . '-ShownMax';

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    # disable params
    return;

    my @Params = (
        {
            Desc  => 'Shown',
            Name  => $Self->{PrefKeyShown},
            Block => 'Option',

            #            Block => 'Input',
            Data => {
                TicketOpen => 'Customers with open Ticket',
                All        => 'All Customers',
            },
            SelectedID => $Self->{Limit},
        },
        {
            Desc  => 'Max. shown',
            Name  => $Self->{PrefKeyShownMax},
            Block => 'Option',

            #            Block => 'Input',
            Data => {
                1_000  => ' 1.000 (e. g. 60kb data)',
                2_000  => ' 2.000 (e. g. 120k data - performance issue on firefox)',
                10_000 => '10.000 (e. g. 600k data - performance issue on all browsers)',
            },
            SelectedID => $Self->{Limit},
        },
    );

    return @Params;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} },
        Link                      => $Self->{LayoutObject}->{Baselink} . 'Action=AgentCustomerMap',
        LinkTitle                 => 'Detail',
        PreferencesReloadRequired => 1,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->{LayoutObject}->Block(
        Name => 'ContentLargeCustomerMapData',
        Data => {
            %{ $Self->{Config} },
            Name      => $Self->{Name},
            Latitude  => $Self->{UserCustomerMapLatitude} || $Self->{Config}->{DefaultLatitude},
            Longitude => $Self->{UserCustomerMapLongitude} || $Self->{Config}->{DefaultLongitude},
            Zoom      => $Self->{UserCustomerMapZoom} || $Self->{Config}->{DefaultZoom},
            Width     => '100%',
            Height    => '400px',
        },
    );

    my $Content = $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentDashboardCustomerMap',
        Data         => {
            %{ $Self->{Config} },
            Name => $Self->{Name},
        },
    );

    return $Content;
}

1;
