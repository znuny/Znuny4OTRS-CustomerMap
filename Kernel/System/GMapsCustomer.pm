# --
# Kernel/System/GMapsCustomer.pm - a GMaps customer
# Copyright (C) 2001-2011 Martin Edenhofer, http://edenhofer.de/
# Copyright (C) 2012-2013 Znuny GmbH, http://znuny.com/
# --
# $Id: $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GMapsCustomer;

use strict;
use warnings;

use Kernel::System::CustomerUser;
use Kernel::System::GMaps;
use Kernel::System::Time;
use Kernel::System::Ticket;
use Kernel::System::JSON;
use Kernel::System::VirtualFS;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

=head1 NAME

Kernel::System::GMapsCustomer - a GMaps customer lib

=head1 SYNOPSIS

All GMaps customer functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::GMapsCustomer;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $GMapsCustomerObject = Kernel::System::GMapsCustomer->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject LogObject MainObject EncodeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{GMapsObject}        = Kernel::System::GMaps->new( %{$Self} );
    $Self->{CustomerUserObject} = Kernel::System::CustomerUser->new( %{$Self} );
    $Self->{TimeObject}         = Kernel::System::Time->new( %{$Self} );
    $Self->{TicketObject}       = Kernel::System::Ticket->new( %{$Self} );
    $Self->{JSONObject}         = Kernel::System::JSON->new( %{$Self} );
    $Self->{VirtualFSObject}    = Kernel::System::VirtualFS->new( %{$Self} );

    # required attributes
    $Self->{RequiredAttributes} = ['UserCity'];

    # attribute map
    $Self->{MapAttribtes} = {
        'UserStreet'  => 'UserStreet',
        'UserCity'    => 'UserCity',
        'UserCountry' => 'UserCountry',
    };

    # open ticket state types
    $Self->{StateType} = [ 'new', 'open', 'pending reminder', 'pending auto' ];

    return $Self;
}

=item DataBuild()

return the content of requested URL

    my $Success = $GMapsCustomerObject->DataBuild();

=cut

sub DataBuild {
    my ( $Self, %Param ) = @_;

    my %List = $Self->{CustomerUserObject}->CustomerUserList(
        Valid => 1,
    );

    my @Data;
    my $Counter      = 0;
    my $CounterLimit = 120_000;
    USER:
    for my $UserID ( sort keys %List ) {
        my %Customer = $Self->{CustomerUserObject}->CustomerUserDataGet(
            User => $UserID,
        );

        # check required infos
        for my $Key ( @{ $Self->{RequiredAttributes} } ) {
            next USER if !$Customer{$Key};
        }

        # cleanup
        for my $Key ( keys %Customer ) {
            next if !$Customer{$Key};
            $Customer{$Key} =~ s/(\r|\n|\t)//g;
        }

        # geo lookup
        my $Query;
        for my $KeyOrig (qw(UserStreet UserCity UserCountry)) {
            my $Key = $Self->{MapAttribtes}->{$KeyOrig};
            next if !$Customer{$Key};
            chomp $Customer{$Key};
            if ($Query) {
                $Query .= ', ';
            }
            $Query .= $Customer{$Key};
        }
        my %Response = $Self->{GMapsObject}->Geocoding(
            Query => $Query,
        );
        next if !%Response;

        sleep 0.3;

        # required check
        next if $Response{Status} !~ /ok/i;

        # counter check
        $Counter++;
        last USER if $Counter == $CounterLimit;

        my $Count = $Self->{TicketObject}->TicketSearch(
            Result            => 'COUNT',
            StateType         => $Self->{StateType},
            CustomerUserLogin => $Customer{UserLogin},
            UserID            => 1,
        );
        if ( $Self->{ConfigObject}->Get('Znuny4OTRSCustomerMapOnlyOpenTickets') ) {
            next if !$Count;
        }
        push @Data, [ $Response{Latitude}, $Response{Longitude}, $Customer{UserLogin}, $Count ];
    }

    if ( !@Data ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message =>
                "No Customer Data found with 'UserCity' attribute (UserStreet, UserCity and UserCountry is used in generel)!",
        );
        return;
    }

    my $Content = $Self->{JSONObject}->Encode(
        Data => \@Data,
    );

    $Self->{VirtualFSObject}->Delete(
        Filename        => '/CMapsCustomerMap/Data.json',
        DisableWarnings => 1,
    );

    my $Success = $Self->{VirtualFSObject}->Write(
        Content  => \$Content,
        Filename => '/CMapsCustomerMap/Data.json',
        Mode     => 'utf8',
    );
    return if !$Success;
    return scalar @Data;
}

=item DataRead()

read data and return json string

    my $ContentJSONRef = $GMapsCustomerObject->DataRead();

=cut

sub DataRead {
    my ( $Self, %Param ) = @_;

    my %File = $Self->{VirtualFSObject}->Read(
        Filename        => '/CMapsCustomerMap/Data.json',
        Mode            => 'utf8',
        DisableWarnings => 1,
    );
    return '{}' if !%File;
    return $File{Content};
}
1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

