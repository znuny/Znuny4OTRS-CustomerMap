# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GMapsCustomer;

use strict;
use warnings;
use utf8;

use Time::HiRes qw(usleep);

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
    'Kernel::System::VirtualFS',
    'Kernel::System::Time',
);

=head1 NAME

Kernel::System::GMapsCustomer - a GMaps customer lib

=head1 SYNOPSIS

All GMaps customer functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $GMapsCustomerObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $StateObject  = $Kernel::OM->Get('Kernel::System::State');

    my $Self = {};
    bless( $Self, $Type );

    # required attributes
    $Self->{RequiredAttributes}
        = $ConfigObject->Get('Znuny::CustomerMap::RequiredCustomerDataAttributes') || ['UserCity'];

    # attribute map
    $Self->{MapAttributes} = $ConfigObject->Get('Znuny::CustomerMap::CustomerDataAttributes') || {
        UserStreet  => 'UserStreet',
        UserCity    => 'UserCity',
        UserCountry => 'UserCountry',
    };

    $Self->{StateType} = [ 'new', 'open', 'pending reminder', 'pending auto' ];
    @{ $Self->{OpenStateIDs} } = $StateObject->StateGetStatesByType(
        StateType => $Self->{StateType},
        Result    => 'ID',
    );

    $Self->{CacheType} = 'GMapsCustomerMap';

    # This Cache key will store a hash of addresses to geo location assignments.
    #
    # Each address to geo location assignment will have its own TTL.
    #
    # Each call (normally done nightly) will set the cache TTL to one year ahead.
    # So this cache key only will be deleted by manual cache deletion.
    #
    # Reason: Address to geo location may become huge on big systems
    # and is required just once every night.
    #
    # To avoid storing 100,000s of address keys the TTL will be assigned to each address key.
    $Self->{CacheTTL} = 365 * ( 24 * 60 * 60 );

    return $Self;
}

=head2 DataBuild()

return the content of requested URL

    my $Success = $GMapsCustomerObject->DataBuild();

=cut

sub DataBuild {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $GMapsObject        = $Kernel::OM->Get('Kernel::System::GMaps');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject         = $Kernel::OM->Get('Kernel::System::JSON');
    my $VirtualFSObject    = $Kernel::OM->Get('Kernel::System::VirtualFS');
    my $DBObject           = $Kernel::OM->Get('Kernel::System::DB');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $CacheObject        = $Kernel::OM->Get('Kernel::System::Cache');
    my $CacheKey           = 'AddressToGeolocation';
    my $InternalCacheTTL   = 86400 * ( $ConfigObject->Get('ZnunyCustomerMapCustomerCacheTTL') // 30 );
    my $OnlyOpenTickets    = $ConfigObject->Get('Znuny::CustomerMap::CustomerSelection') // 1;

    # Getting data is triggered once every night so one systemtime for cache comparison is enough
    my $SystemTime = $TimeObject->SystemTime();

    my $Cache = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    if ( ref $Cache ne 'HASH' ) {
        $Cache = {};
    }

    my $SQL = '
        SELECT DISTINCT customer_user_id
        FROM   ticket t
    ';

    if ($OnlyOpenTickets) {
        $SQL .= 'WHERE t.ticket_state_id IN(' . ( join ',', @{ $Self->{OpenStateIDs} } ) . ')';
    }
    return if !$DBObject->Prepare( SQL => $SQL );

    # fetch the result
    my @CustomerUserIDs;
    CUSTOMERUSERID:
    while ( my @Row = $DBObject->FetchrowArray() ) {
        next CUSTOMERUSERID if !$Row[0];
        push @CustomerUserIDs, $Row[0];
    }

    my %NewCache;
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
            $Customer{$Key} =~ s{(\r|\n|\t)}{}g;
        }

        my $Query;
        MAPATTRIBUTE:
        for my $KeyOrig ( sort keys %{ $Self->{MapAttributes} } ) {
            my $Key = $Self->{MapAttributes}->{$KeyOrig};
            next MAPATTRIBUTE if !$Customer{$Key};
            chomp $Customer{$Key};
            if ( defined $Query ) {
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

        next CUSTOMERUSERID if $OnlyOpenTickets && !$Count;

        if (
            $Cache->{$Query}
            && defined $Cache->{$Query}->{Latitude}
            && defined $Cache->{$Query}->{Longitude}
            )
        {
            $Counter++;
            last CUSTOMERUSERID if $Counter == $CounterLimit;

            if ( $Cache->{$Query}->{TTL} > $SystemTime ) {
                push @Data, [
                    $Cache->{$Query}->{Latitude},
                    $Cache->{$Query}->{Longitude},
                    $Customer{UserLogin},
                    $Count
                ];
                next CUSTOMERUSERID;
            }

            # Cache itself lives forever
            # so if the TTL of an exisiting address query
            # aged out, we delete it manually
            #
            # Reason: if the Geocoding response fails, and will fail continually
            # (Example: an old address doesn't exist anymore because a street/city was renamed)
            # the old stored cache entry neither would be overwritten
            # nor deleted so deleting here is necessary for cache sanity
            #
            # For customers that don't have open tickets anymore over years
            # it will still be necessary to delete the cache manually every 3-5 years
            # (which normally should be done if a system gets upgraded to a new OTRS version)
            delete $Cache->{$Query};
        }

        my %Response = $GMapsObject->Geocoding(
            Query => $Query,
        );

        usleep(300000);

        next CUSTOMERUSERID if !%Response;
        next CUSTOMERUSERID if $Response{Status} !~ m{ok}i;

        $Counter++;
        last CUSTOMERUSERID if $Counter == $CounterLimit;

        push @Data, [
            $Response{Latitude},
            $Response{Longitude},
            $Customer{UserLogin},
            $Count
        ];

        $NewCache{$Query} = {
            Latitude  => $Response{Latitude},
            Longitude => $Response{Longitude},
            TTL       => $SystemTime + $InternalCacheTTL,
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

=head2 DataRead()

read data and return JSON string

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
