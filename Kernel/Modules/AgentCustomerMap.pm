# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerMap;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::CustomerUser;
use Kernel::System::GMapsCustomer;

sub new {
    my ( $Type, %Param ) = @_;

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

    #
    # update preferences
    #
    if ( $Self->{Subaction} eq 'Update' ) {
        for my $Key (qw( Latitude Longitude Zoom )) {
            my $Value      = $ParamObject->GetParam( Param => $Key );
            my $SessionKey = 'UserCustomerMap' . $Key;

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

    #
    # get user data
    #
    if ( $Self->{Subaction} eq 'Customer' ) {
        my $Login    = $ParamObject->GetParam( Param => 'Login' );
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

    #
    # deliver data
    #
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

    # Fetch first dashboard backend config which uses the customer map module.
    my $Config = $ConfigObject->Get('DashboardBackend');
    if ( !IsHashRefWithData($Config) ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No dashbord backend config found.',
        );
    }

    my @CustomerMapDashboardBackendConfigs = map { $Config->{$_} } grep {
        $Config->{$_}->{Module} eq 'Kernel::Output::HTML::Dashboard::CustomerMap'
    } keys %{$Config};
    if ( !@CustomerMapDashboardBackendConfigs ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No dashbord backend config for customer map found.',
        );
    }
    my $CustomerMapDashboardBackendConfig = shift @CustomerMapDashboardBackendConfigs;

    my $JSON = $GMapsCustomerObject->DataRead();
    if ($JSON) {
        $LayoutObject->Block(
            Name => 'ContentLargeCustomerMapData',
            Data => {
                %{$CustomerMapDashboardBackendConfig},
                Latitude => $Self->{UserCustomerMapLatitude}
                    || $CustomerMapDashboardBackendConfig->{DefaultLatitude},
                Longitude => $Self->{UserCustomerMapLongitude}
                    || $CustomerMapDashboardBackendConfig->{DefaultLongitude},
                Zoom   => $Self->{UserCustomerMapZoom} || $CustomerMapDashboardBackendConfig->{DefaultZoom},
                Width  => '100%',
                Height => '550px',
            },
        );
    }
    else {
        $LayoutObject->Block(
            Name => 'ContentLargeCustomerMapConfigMissing',
            Data => {
                %{$CustomerMapDashboardBackendConfig},
            },
        );
    }

    $Param{Map} = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardCustomerMap',
        Data         => {
            %{$CustomerMapDashboardBackendConfig},
        },
    );

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
