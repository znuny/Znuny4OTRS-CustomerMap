# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerMap;

use strict;
use warnings;

use Kernel::System::CustomerUser;
use Kernel::System::GMapsCustomer;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    OBJECT:
    for my $Object (qw(TicketObject ParamObject DBObject QueueObject LayoutObject ConfigObject LogObject)) {
        next OBJECT if $Self->{$Object};
        $Self->{LayoutObject}->FatalError( Message => "Got no $Object!" );
    }

    $Self->{CustomerUserObject}  = Kernel::System::CustomerUser->new(%Param);
    $Self->{GMapsCustomerObject} = Kernel::System::GMapsCustomer->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # update preferences
    if ( $Self->{Subaction} eq 'Update' ) {
        for my $Key (qw( Latitude Longitude Zoom )) {
            my $Value = $Self->{ParamObject}->GetParam( Param => $Key );
            my $SessionKey = 'UserCustomerMap' . $Key;

            # update ssession
            $Self->{SessionObject}->UpdateSessionID(
                SessionID => $Self->{SessionID},
                Key       => $SessionKey,
                Value     => $Value,
            );

            # update preferences
            $Self->{UserObject}->SetPreferences(
                UserID => $Self->{UserID},
                Key    => $SessionKey,
                Value  => $Value,
            );
        }
        my $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => {
                Status => 'OK',
            },
        );
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # get user data
    if ( $Self->{Subaction} eq 'Customer' ) {
        my $Login = $Self->{ParamObject}->GetParam( Param => 'Login' );
        my %Customer = $Self->{CustomerUserObject}->CustomerUserDataGet(
            User => $Login,
        );
        my $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => \%Customer,
        );
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # deliver data
    if ( $Self->{Subaction} eq 'Data' ) {
        my $JSON = $Self->{GMapsCustomerObject}->DataRead();
        if ( ref $JSON eq 'SCALAR' ) {
            $JSON = ${$JSON};
        }
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # load backends
    my $Config = $Self->{ConfigObject}->Get('DashboardBackend');
    if ( !$Config ) {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No such config for Dashboard',
        );
    }

    CONFIG:
    for my $Name ( sort keys %{$Config} ) {
        next CONFIG if $Config->{$Name}->{Module} ne 'Kernel::Output::HTML::DashboardCustomerMap';

        my $JSON = $Self->{GMapsCustomerObject}->DataRead();
        if ( !$JSON ) {
            $Self->{LayoutObject}->Block(
                Name => 'ContentLargeCustomerMapConfig',
                Data => {
                    %{ $Config->{$Name} },
                    Name => $Self->{Name},
                },
            );
        }
        else {
            $Self->{LayoutObject}->Block(
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
        $Param{Map} = $Self->{LayoutObject}->Output(
            TemplateFile => 'AgentDashboardCustomerMap',
            Data         => {
                %{ $Config->{$Name} },
                Name => $Name,
            },
        );
        last CONFIG;
    }

    # start with page ...
    my $Output = $Self->{LayoutObject}->Header();
    $Output .= $Self->{LayoutObject}->NavigationBar();
    $Output .= $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentCustomerMap',
        Data         => \%Param
    );
    $Output .= $Self->{LayoutObject}->Footer();
    return $Output;
}

1;
