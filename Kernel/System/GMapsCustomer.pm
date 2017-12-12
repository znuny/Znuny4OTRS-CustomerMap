# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GMapsCustomer;

use strict;
use warnings;
use Time::HiRes qw(usleep);

use Kernel::System::CustomerUser;
use Kernel::System::GMaps;
use Kernel::System::Time;
use Kernel::System::Ticket;
use Kernel::System::JSON;
use Kernel::System::VirtualFS;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::GMaps',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Time',
    'Kernel::System::VirtualFS',
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
    my $StateObject  = $Kernel::OM->Get('Kernel::System::State');

    # required attributes
    $Self->{RequiredAttributes}
        = $ConfigObject->Get('Znuny4OTRSCustomerMapRequiredCustomerDataAttributes') || ['UserCity'];

    # attribute map
    $Self->{MapAttributes} = $ConfigObject->Get('Znuny4OTRSCustomerMapCustomerDataAttributes') || {
        'UserStreet'  => 'UserStreet',
        'UserCity'    => 'UserCity',
        'UserCountry' => 'UserCountry',
    };

    $Self->{TicketStateTypes} = [ 'new', 'open', 'pending reminder', 'pending auto' ];
    @{ $Self->{OpenStateIDs} } = $StateObject->StateGetStatesByType(
        StateType => $Self->{TicketStateTypes},
        Result    => 'ID',
    );

    $Self->{CacheType} = 'GMapsCustomerMap';

    # This Cache Key will store a hash of Address to Geolocation assignments
    #
    # Each Address to Geolocation assignment will have it's own TTL
    #
    # each call of this Routine (normally done nightly)
    # will set the CacheTTL to 1 year ahead
    # so this cache key just gets deleted by manual cache deletion
    #
    # Reason for it: Address to Geolocation may become huge on big systems
    # and is required just once every night
    #
    # To avoid storing 100.000s of Address Keys the TTL will be assigned to each Address Key
    $Self->{CacheTTL} = 365 * 86400;

    return $Self;
}

=item DataBuild()

return the content of requested URL

    my $Success = $GMapsCustomerObject->DataBuild();

=cut

sub DataBuild {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $GmapsObject        = $Kernel::OM->Get('Kernel::System::GMaps');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject         = $Kernel::OM->Get('Kernel::System::JSON');
    my $VirtualFSObject    = $Kernel::OM->Get('Kernel::System::VirtualFS');
    my $DBObject           = $Kernel::OM->Get('Kernel::System::DB');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $CacheObject        = $Kernel::OM->Get('Kernel::System::Cache');
    my $CacheKey           = 'AddressToGeolocation';
    my $InternalCacheTTL   = 86400 * ( $ConfigObject->Get('Znuny4OTRSCustomerMapCustomerCacheTTL') // 30 );
    my $OnlyOpenTickets    = $ConfigObject->Get('Znuny4OTRSCustomerMapOnlyOpenTickets') // 1;

    # Getting Data is triggered once every night so one systemtime for cache comparison is enough
    my $SystemTime = $TimeObject->SystemTime();

    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    my %NewCache = ();

    if ( ref $Cache ne 'HASH' ) {
        $Cache = {};
    }

    my $SQL = ''
        . 'SELECT DISTINCT customer_user_id'
        . ' FROM ticket t';

    if ($OnlyOpenTickets) {
        $SQL .= ' WHERE t.ticket_state_id IN(' . ( join ',', @{ $Self->{OpenStateIDs} } ) . ')';
    }

    return if !$DBObject->Prepare( SQL => $SQL );

    my @CustomerUserIDs;

    # fetch the result
    ROW:
    while ( my @Data = $DBObject->FetchrowArray() ) {

        next ROW if !$Data[0];

        push @CustomerUserIDs, $Data[0];
    }

    my @Data;
    my $Counter      = 0;
    my $CounterLimit = 120_000;

    CUSTOMERUSERID:
    for my $UserID (@CustomerUserIDs) {
        my %Customer = $CustomerUserObject->CustomerUserDataGet(
            User => $UserID,
        );
        next CUSTOMERUSERID if !%Customer;

        # check required infos
        for my $Key ( @{ $Self->{RequiredAttributes} } ) {
            next CUSTOMERUSERID if !$Customer{$Key};
        }

        # cleanup
        CUSTOMER:
        for my $Key ( sort keys %Customer ) {
            next CUSTOMER if !$Customer{$Key};
            $Customer{$Key} =~ s/(\r|\n|\t)//g;
        }

        my $Query;
        MAPATTRIBUTES:
        for my $KeyOrig ( sort keys %{ $Self->{MapAttributes} } ) {
            my $Key = $Self->{MapAttributes}->{$KeyOrig};
            next MAPATTRIBUTES if !$Customer{$Key};
            chomp $Customer{$Key};
            if ($Query) {
                $Query .= ', ';
            }
            $Query .= $Customer{$Key};
        }

        my $Count = $TicketObject->TicketSearch(
            Result            => 'COUNT',
            StateType         => $Self->{StateType},
            CustomerUserLogin => $Customer{UserLogin},
            UserID            => 1,
        );

        next CUSTOMERUSERID if ( $OnlyOpenTickets && !$Count );

        if (
            $Cache->{$Query}
            && defined $Cache->{$Query}->{Latitude}
            && defined $Cache->{$Query}->{Longitude}
            )
        {

            $Counter++;
            last CUSTOMERUSERID if $Counter == $CounterLimit;

            if ( $Cache->{$Query}->{TTL} > $SystemTime ) {
                push @Data,
                    [ $Cache->{$Query}->{Latitude}, $Cache->{$Query}->{Longitude}, $Customer{UserLogin}, $Count ];
                next CUSTOMERUSERID;
            }

            # Cache itself lives forever
            # so if the TTL of an exisiting Address Query
            # aged out, we delete it manually
            #
            # Reason: if the Geocoding response fails, and will fail continually
            # (Example: an old Address doesn't exist any more because a Street/City was renamed)
            # the old stored Cache Entry neither would be overwritten
            # nore deleted so deleting here is necessary for cache sanity
            #
            # For customers that don't have open tickets any more over years
            # it will be still necessary to delete the cache manually every 3-5 years
            # (which normally should be done if a system gets upgraded to a new OTRS Version)
            delete $Cache->{$Query};
        }

        my %Response = $GmapsObject->Geocoding(
            Query => $Query,
        );

        usleep(300000);

        next CUSTOMERUSERID if !%Response;

        next CUSTOMERUSERID if $Response{Status} !~ /ok/i;

        $Counter++;
        last CUSTOMERUSERID if $Counter == $CounterLimit;

        push @Data, [ $Response{Latitude}, $Response{Longitude}, $Customer{UserLogin}, $Count ];

        $NewCache{$Query} = {
            Latitude  => $Response{Latitude},
            Longitude => $Response{Longitude},
            TTL       => ( $SystemTime + $InternalCacheTTL ),
        };
    }

    %NewCache = (
        %{$Cache},
        %NewCache,
    );

    $CacheObject->Configure(
        CacheInMemory  => 0,
        CacheInBackend => 1,
    );

    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%NewCache,
    );

    $VirtualFSObject->Delete(
        Filename        => '/GMapsCustomerMap/Data.json',
        DisableWarnings => 1,
    );

    return 0 if !@Data;

    my $Content = $JSONObject->Encode(
        Data => \@Data,
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
    my $VirtualFSObject = $Kernel::OM->Get('Kernel::System::VirtualFS');

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

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
