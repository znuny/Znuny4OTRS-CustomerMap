# --
# Kernel/System/GMapsCustomer.pm - a GMaps customer
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
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

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::GMapsCustomer',
);

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

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    
    # required attributes
    $Self->{RequiredAttributes} = $ConfigObject->Get( 'Znuny4OTRSCustomerMapRequiredCustomerDataAttributes' ) || ['UserCity'];

    # attribute map
    $Self->{MapAttributes} = $ConfigObject->Get('Znuny4OTRSCustomerMapCustomerDataAttributes') || {
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
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $GmapsObject = $Kernel::OM->Get('Kernel::System::GMaps');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');
    my $VirtualFSObject  = $Kernel::OM->Get('Kernel::System::VirtualFS');
    
    my %List = $CustomerUserObject->CustomerUserList(
        Valid => 1,
    );

    my @Data;
    my $Counter      = 0;
    my $CounterLimit = 120_000;
    USER:
    for my $UserID ( sort keys %List ) {
        my %Customer = $CustomerUserObject->CustomerUserDataGet(
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
        for my $KeyOrig ( keys %{$Self->{MapAttributes}} ) {
            my $Key = $Self->{MapAttributes}->{$KeyOrig};
            next if !$Customer{$Key};
            chomp $Customer{$Key};
            if ($Query) {
                $Query .= ', ';
            }
            $Query .= $Customer{$Key};
        }
        my %Response = $GmapsObject->Geocoding(
            Query => $Query,
        );
        next if !%Response;

        select undef, undef, undef, 0.3;

        # required check
        next if $Response{Status} !~ /ok/i;

        # counter check
        $Counter++;
        last USER if $Counter == $CounterLimit;

        my $Count = $TicketObject->TicketSearch(
            Result            => 'COUNT',
            StateType         => $Self->{StateType},
            CustomerUserLogin => $Customer{UserLogin},
            UserID            => 1,
        );
        if ( $ConfigObject->Get('Znuny4OTRSCustomerMapOnlyOpenTickets') ) {
            next if !$Count;
        }
        push @Data, [ $Response{Latitude}, $Response{Longitude}, $Customer{UserLogin}, $Count ];
    }

    if ( !@Data ) {
        $LogObject->Log(
            Priority => 'error',
            Message =>
                "No Customer Data found with 'UserCity' attribute (UserStreet, UserCity and UserCountry is used in generel)!",
        );
        return;
    }

    my $Content = $JSONObject->Encode(
        Data => \@Data,
    );

    $VirtualFSObject->Delete(
        Filename        => '/GMapsCustomerMap/Data.json',
        DisableWarnings => 1,
    );

    my $Success = $VirtualFSObject->Write(
        Content  => \$Content,
        Filename => '/GMapsCustomerMap/Data.json',
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
    my $VirtualFSObject  = $Kernel::OM->Get('Kernel::System::VirtualFS');

    my %File = $VirtualFSObject->Read(
        Filename        => '/GMapsCustomerMap/Data.json',
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

