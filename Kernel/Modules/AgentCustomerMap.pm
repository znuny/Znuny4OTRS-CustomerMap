# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 0000000000000000000000000000000000000000 - Kernel/Modules/AgentCustomerMap.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerMap;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::CustomerUser;
use Kernel::System::GMapsCustomer;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject         = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject        = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GMapsCustomerObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');
    my $SessionObject       = $Kernel::OM->Get('Kernel::System::AuthSession');
    my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
    my $CustomerUserObject  = $Kernel::OM->Get('Kernel::System::CustomerUser');

# ---
    # update preferences
# ---
    if ( $Self->{Subaction} eq 'Update' ) {
        KEY:
        for my $Key (qw( Latitude Longitude Zoom )) {
            my $Value = $ParamObject->GetParam( Param => $Key );
            my $SessionKey = 'UserCustomerMap' . $Key;

            # update ssession
            $SessionObject->UpdateSessionID(
                SessionID => $Self->{SessionID},
                Key       => $SessionKey,
                Value     => $Value,
            );

            # update preferences
            $UserObject->SetPreferences(
                UserID => $Self->{UserID},
                Key    => $SessionKey,
                Value  => $Value,
            );
        }
        my $JSON = $LayoutObject->JSONEncode(
            Data => {
                Status => 'OK',
            },
        );
        return $LayoutObject->Attachment(
            ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

# ---
    # get user data
# ---
    if ( $Self->{Subaction} eq 'Customer' ) {
        my $Login = $ParamObject->GetParam( Param => 'Login' );
        my %Customer = $CustomerUserObject->CustomerUserDataGet(
            User => $Login,
        );
        my $JSON = $LayoutObject->JSONEncode(
            Data => \%Customer,
        );
        return $LayoutObject->Attachment(
            ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

# ---
    # deliver data
# ---
    if ( $Self->{Subaction} eq 'Data' ) {
        my $JSON = $GMapsCustomerObject->DataRead();
        if ( ref $JSON eq 'SCALAR' ) {
            $JSON = ${$JSON};
        }
        return $LayoutObject->Attachment(
            ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # load backends
    my $Config = $ConfigObject->Get('DashboardBackend');
    if ( !$Config ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No such config for Dashboard',
        );
    }

    CONFIG:
    for my $Name ( sort keys %{$Config} ) {
        next CONFIG if $Config->{$Name}->{Module} ne 'Kernel::Output::HTML::Dashboard::CustomerMap';

        my $JSON = $GMapsCustomerObject->DataRead();
        if ( !$JSON ) {
            $LayoutObject->Block(
                Name => 'ContentLargeCustomerMapConfig',
                Data => {
                    %{ $Config->{$Name} },
                    Name => $Self->{Name},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'ContentLargeCustomerMapData',
                Data => {
                    %{ $Config->{$Name} },
                    Name     => $Name,
                    Latitude => $Self->{UserCustomerMapLatitude}
                        || $Config->{$Name}->{DefaultLatitude},
                    Longitude => $Self->{UserCustomerMapLongitude}
                        || $Config->{$Name}->{DefaultLongitude},
                    Zoom => $Self->{UserCustomerMapZoom} || $Config->{$Name}->{DefaultZoom},
                    Width  => '100%',
                    Height => '550px',
                },
            );
        }
        $Param{Map} = $LayoutObject->Output(
            TemplateFile => 'AgentDashboardCustomerMap',
            Data         => {
                %{ $Config->{$Name} },
                Name => $Name,
            },
        );
        last CONFIG;
    }

    # start with page ...
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentCustomerMap',
        Data         => \%Param
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

1;
