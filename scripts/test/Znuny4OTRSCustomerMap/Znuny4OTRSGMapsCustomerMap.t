# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

# get needed objects
my $ZnunyHelperObject   = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $HelperObject        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject        = $Kernel::OM->Get('Kernel::System::Ticket');
my $GMapsCustomerObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');
my $CacheObject         = $Kernel::OM->Get('Kernel::System::Cache');
my $JSONObject          = $Kernel::OM->Get('Kernel::System::JSON');
my $SysConfigObject     = $Kernel::OM->Get('Kernel::System::SysConfig');
my $ConfigObject        = $Kernel::OM->Get('Kernel::Config');

my @RandomIDs;
for ( 0 .. 2 ) {
    push @RandomIDs, $HelperObject->GetRandomID();
}

my @CustomerTemplate = (
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomIDs[0],
        UserLastname   => $RandomIDs[0],
        UserCustomerID => $RandomIDs[0],
        UserLogin      => $RandomIDs[0],
        UserPassword   => $RandomIDs[0],
        UserEmail      => "$RandomIDs[0]\@example.com",
        UserStreet     => 'Marienstraße 11',
        UserZip        => '10117',
        UserCity       => 'Berlin',
        UserCountry    => 'Germany',
    },
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomIDs[1],
        UserLastname   => $RandomIDs[1],
        UserCustomerID => $RandomIDs[1],
        UserLogin      => $RandomIDs[1],
        UserPassword   => $RandomIDs[1],
        UserEmail      => "$RandomIDs[1]\@example.com",
        UserStreet     => 'Martinsbruggstrasse 35',
        UserZip        => '9016',
        UserCity       => 'St. Gallen',
        UserCountry    => 'Switzerland',
    },
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomIDs[2],
        UserLastname   => $RandomIDs[2],
        UserCustomerID => $RandomIDs[2],
        UserLogin      => $RandomIDs[2],
        UserPassword   => $RandomIDs[2],
        UserEmail      => "$RandomIDs[2]\@example.com",
        UserStreet     => 'Willy-Brandt-Straße 1',
        UserZip        => '10557',
        UserCity       => 'Berlin',
        UserCountry    => 'Germany',
    },
);

my @CustomerUsers;
my $CustomerUserCounter = 0;
for my $CustomerUser (@CustomerTemplate) {
    my %CustomerCreated;
    $CustomerUserCounter++;
    my $CustomerUserLogin = $ZnunyHelperObject->_CustomerUserCreateIfNotExists( %{$CustomerUser} );

    $Self->True(
        $CustomerUserLogin,
        "Creation of customer user $CustomerUserLogin must succeed.",
    );

    %CustomerCreated = (
        %{$CustomerUser},
        CustomerLogin => $CustomerUserLogin,
    );

    if ( $CustomerUserCounter > 1 ) {
        my $TicketID = $HelperObject->TicketCreate(
            Title        => 'UnitTest ticket',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerID   => $CustomerUser->{UserCustomerID},
            CustomerUser => $CustomerUserLogin,
            OwnerID      => 1,
            UserID       => 1,
        );

        $Self->True(
            $TicketID,
            "Creation of ticket for customer user $CustomerUserLogin.",
        );

        $CustomerCreated{TicketID} = $TicketID;
    }
    push @CustomerUsers, \%CustomerCreated;
}

$CacheObject->Delete(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

my $Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->False(
    $Cache,
    'Cache must be empty.',
);

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    'Cache must be present after map has been built.',
);

my $JSON = $GMapsCustomerObject->DataRead();
if ( ref $JSON eq 'SCALAR' ) {
    $JSON = $$JSON;
}

$Self->True(
    $JSON,
    'JSON for map must be present.',
);

my $MapData = $JSONObject->Decode(
    Data => $JSON,
);

$CustomerUserCounter = 0;
for my $CustomerUser (@CustomerUsers) {
    $CustomerUserCounter++;

    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    if ( $CustomerUserCounter > 1 ) {
        $Self->True(
            $Cache->{$CacheKey},
            "Cache entry for customer user $CustomerUser->{UserLogin} must be found.",
        );

        # Check if the Lat, Lng and UserLogin are in the JSON Data
        my $Success;
        for my $Map ( @{$MapData} ) {

            if (
                $Map->[0] eq $Cache->{$CacheKey}->{Latitude}
                && $Map->[1] eq $Cache->{$CacheKey}->{Longitude}
                && $Map->[2] eq $CustomerUser->{UserLogin}
                )
            {
                $Success = 1;
            }
        }

        $Self->True(
            $Success,
            "LatLng entry must be found for customer user $CustomerUser->{UserLogin}.",
        );
    }
    else {
        $Self->False(
            $Cache->{$CacheKey},
            "Cache entry for customer user $CustomerUser->{UserLogin} must not be present.",
        );
    }
}

# Now create an additional ticket for our first customer
my $TicketID = $HelperObject->TicketCreate(
    Title        => 'UnitTest ticket',
    Queue        => 'Raw',
    Lock         => 'unlock',
    Priority     => '3 normal',
    State        => 'open',
    CustomerID   => $CustomerUsers[0]->{UserCustomerID},
    CustomerUser => $CustomerUsers[0]->{UserLogin},
    OwnerID      => 1,
    UserID       => 1,
);

$Self->True(
    $TicketID,
    "Ticket for customer user $CustomerUsers[0]->{UserLogin} must have been created successfully.",
);

$CustomerUsers[0]->{TicketID} = $TicketID;

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    'Cache entry must be present after building the map.',
);

$JSON = $GMapsCustomerObject->DataRead();
if ( ref $JSON eq 'SCALAR' ) {
    $JSON = $$JSON;
}

$Self->True(
    $JSON,
    'JSON for map must be present after ticket creation.',
);

$MapData = $JSONObject->Decode(
    Data => $JSON,
);

for my $CustomerUser (@CustomerUsers) {

    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        "Cache entry for customer user $CustomerUser->{UserLogin} must be present after adding ticket.",
    );

    # Check if the Lat, Lng and UserLogin are in the JSON Data
    my $Success;
    for my $Map ( @{$MapData} ) {
        if (
            $Map->[0] eq $Cache->{$CacheKey}->{Latitude}
            && $Map->[1] eq $Cache->{$CacheKey}->{Longitude}
            && $Map->[2] eq $CustomerUser->{UserLogin}
            )
        {
            $Success = 1;
        }
    }

    $Self->True(
        $Success,
        'LatLng entry for customer user $CustomerUser->{UserLogin} must be present after adding ticket.',
    );
}

# now lets close the ticket of our first customer
# Address cache should still contail all three records
# whereas geodata JSON should just have two records

my $Success = $TicketObject->TicketStateSet(
    State    => 'closed successful',
    TicketID => $CustomerUsers[0]->{TicketID},
    UserID   => 1,
);

$Self->True(
    $Success,
    'Ticket must have been closed successfully',
);

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    'cache entry after building map must be present.',
);

$JSON = $GMapsCustomerObject->DataRead();
if ( ref $JSON eq 'SCALAR' ) {
    $JSON = $$JSON;
}

$Self->True(
    $JSON,
    'JSON for map must be present after closing ticket.',
);

$MapData = $JSONObject->Decode(
    Data => $JSON,
);

$CustomerUserCounter = 0;
for my $CustomerUser (@CustomerUsers) {
    $CustomerUserCounter++;
    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        'Cache entry for customer user $CustomerUser->{UserLogin} must be present after closing ticket.',
    );

    # Check if the Lat, Lng and UserLogin are in the JSON Data
    my $Success;
    for my $Map ( @{$MapData} ) {
        if (
            $Map->[0] eq $Cache->{$CacheKey}->{Latitude}
            && $Map->[1] eq $Cache->{$CacheKey}->{Longitude}
            && $Map->[2] eq $CustomerUser->{UserLogin}
            )
        {
            $Success = 1;
        }
    }
    if ( $CustomerUserCounter > 1 ) {
        $Self->True(
            $Success,
            'LatLng entry for customer user $CustomerUser->{UserLogin} must be present after closing ticket.',
        );
    }
    else {
        $Self->False(
            $Success,
            'LatLng entry for customer user $CustomerUser->{UserLogin} must not be present after closing ticket.',
        );
    }
}

# and finally check if we have at least our 3 customers
# if all customers that have tickets (no matter if close or open) should be shown on the map not only those with open tickets
$ConfigObject->Set(
    Key   => 'Znuny4OTRS::CustomerMap::CustomerSelection',
    Value => 0
);

$Kernel::OM->ObjectsDiscard(
    Objects => [
        'Kernel::System::GMapsCustomer',
    ],
);

$GMapsCustomerObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    'Cache entry must be present after switching SysConfig to show all ticket customers.',
);

$JSON = $GMapsCustomerObject->DataRead();
if ( ref $JSON eq 'SCALAR' ) {
    $JSON = $$JSON;
}

$Self->True(
    $JSON,
    'JSON map must be present after switching SysConfig to show all ticket customers.',
);

$MapData = $JSONObject->Decode(
    Data => $JSON,
);

for my $CustomerUser (@CustomerUsers) {
    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        "Cache entry for customer user $CustomerUser->{UserLogin} must be present after switching SysConfig to show all ticket customers.",
    );

    # Check if the Lat, Lng and UserLogin are in the JSON Data
    my $Success;
    for my $Map ( @{$MapData} ) {
        if (
            $Map->[0] eq $Cache->{$CacheKey}->{Latitude}
            && $Map->[1] eq $Cache->{$CacheKey}->{Longitude}
            && $Map->[2] eq $CustomerUser->{UserLogin}
            )
        {
            $Success = 1;
        }
    }

    $Self->True(
        $Success,
        "LatLng entry for customer user $CustomerUser->{UserLogin} must be present after switching SysConfig to show all ticket customers.",
    );
}

1;
