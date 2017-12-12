# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
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
        RestoreSystemConfiguration => 1,
        RestoreDatabase            => 1,
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

my ( $RandomID1, $RandomID2, $RandomID3 )
    = ( $HelperObject->GetRandomID(), $HelperObject->GetRandomID(), $HelperObject->GetRandomID() );
my @CustomerTemplate = (
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomID1,
        UserLastname   => $RandomID1,
        UserCustomerID => $RandomID1,
        UserLogin      => $RandomID1,
        UserPassword   => $RandomID1,
        UserEmail      => "$RandomID1\@example.com",
        UserStreet     => 'Marienstraße 11',
        UserZip        => '10117',
        UserCity       => 'Berlin',
        UserCountry    => 'Germany',
    },
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomID2,
        UserLastname   => $RandomID2,
        UserCustomerID => $RandomID2,
        UserLogin      => $RandomID2,
        UserPassword   => $RandomID2,
        UserEmail      => "$RandomID2\@example.com",
        UserStreet     => 'Martinsbruggstrasse 35',
        UserZip        => '9016',
        UserCity       => 'St. Gallen',
        UserCountry    => 'Switzerland',
    },
    {
        Source         => 'CustomerUser',
        UserFirstname  => $RandomID3,
        UserLastname   => $RandomID3,
        UserCustomerID => $RandomID3,
        UserLogin      => $RandomID3,
        UserPassword   => $RandomID3,
        UserEmail      => "$RandomID3\@example.com",
        UserStreet     => 'Willy-Brandt-Straße 1',
        UserZip        => '10557',
        UserCity       => 'Berlin',
        UserCountry    => 'Germany',
    },
);

my @CustomerUsers;
my $i = 0;
for my $CustomerUser (@CustomerTemplate) {
    my %CustomerCreated;
    $i++;
    my $CustomerUserLogin = $ZnunyHelperObject->_CustomerUserCreateIfNotExists( %{$CustomerUser} );

    $Self->True(
        $CustomerUserLogin,
        "Created CustomerUserLogin $CustomerUserLogin.",
    );

    %CustomerCreated = (
        %{$CustomerUser},
        CustomerLogin => $CustomerUserLogin,
    );

    if ( $i > 1 ) {
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
            "Created TicketID $TicketID for CustomerUser $CustomerUserLogin.",
        );

        $CustomerCreated{TicketID} = $TicketID;
    }
    push @CustomerUsers, \%CustomerCreated;
}

my $Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->False(
    $Cache,
    "Had no cache on start.",
);

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    "Had cache after MapsBuild.",
);

my $JSON = $GMapsCustomerObject->DataRead();

$Self->True(
    $JSON,
    "Had JSON String for Map.",
);

my $MapData = $JSONObject->Decode(
    Data => $$JSON,
);

$i = 0;
for my $CustomerUser (@CustomerUsers) {
    $i++;

    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    if ( $i > 1 ) {
        $Self->True(
            $Cache->{$CacheKey},
            "Had Cache record for $CustomerUser->{UserLogin}",
        );

        my $Success;

        # Check if the Lat, Lng and UserLogin are in the JSON Data
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
            "Had LatLng Entry for $CustomerUser->{UserLogin}",
        );
    }
    else {
        $Self->False(
            $Cache->{$CacheKey},
            "Had No Cache record for $CustomerUser->{UserLogin}",
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
    "Created TicketID $TicketID for CustomerUser $CustomerUsers[0]->{UserLogin}.",
);

$CustomerUsers[0]->{TicketID} = $TicketID;

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    "Had cache after MapsBuild after adding Ticket.",
);

$JSON = $GMapsCustomerObject->DataRead();

$Self->True(
    $JSON,
    "Had JSON String for Map after adding Ticket.",
);

$MapData = $JSONObject->Decode(
    Data => $$JSON,
);

for my $CustomerUser (@CustomerUsers) {

    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        "Had Cache record for $CustomerUser->{UserLogin} after adding Ticket",
    );

    my $Success;

    # Check if the Lat, Lng and UserLogin are in the JSON Data
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
        "Had LatLng Entry for $CustomerUser->{UserLogin} after adding Ticket",
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
    "Closed Ticket successfully",
);

$GMapsCustomerObject->DataBuild();

$Cache = $CacheObject->Get(
    Type => 'GMapsCustomerMap',
    Key  => 'AddressToGeolocation',
);

$Self->True(
    IsHashRefWithData($Cache),
    "Had cache after MapsBuild after closing Ticket.",
);

$JSON = $GMapsCustomerObject->DataRead();

$Self->True(
    $JSON,
    "Had JSON String for Map after closing Ticket.",
);

$MapData = $JSONObject->Decode(
    Data => $$JSON,
);

$i = 0;
for my $CustomerUser (@CustomerUsers) {
    $i++;
    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        "Had Cache record for $CustomerUser->{UserLogin} after closing Ticket",
    );

    my $Success;

    # Check if the Lat, Lng and UserLogin are in the JSON Data
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
    if ( $i > 1 ) {
        $Self->True(
            $Success,
            "Had LatLng Entry for $CustomerUser->{UserLogin} after closing Ticket",
        );
    }
    else {
        $Self->False(
            $Success,
            "Had no LatLng Entry for $CustomerUser->{UserLogin} after closing Ticket",
        );
    }
}

# and finally check if we have at least our 3 customers
# if all customers that have tickets (no matter if close or open) should be shown on the map not only those with open tickets
$ConfigObject->Set(
    Key   => 'Znuny4OTRSCustomerMapOnlyOpenTickets',
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
    "Had cache after MapsBuild after switching SysConfig to show all Ticket Customers.",
);

$JSON = $GMapsCustomerObject->DataRead();

$Self->True(
    $JSON,
    "Had JSON String for Map after switching SysConfig to show all Ticket Customers.",
);

$MapData = $JSONObject->Decode(
    Data => $$JSON,
);

for my $CustomerUser (@CustomerUsers) {
    my $CacheKey = "$CustomerUser->{UserCity}, $CustomerUser->{UserCountry}, $CustomerUser->{UserStreet}";

    # Check that UserStreet, UserCity and UserCountry are in a CacheKey Entry

    $Self->True(
        $Cache->{$CacheKey},
        "Had Cache record for $CustomerUser->{UserLogin} after switching SysConfig to show all Ticket Customers",
    );

    my $Success;

    # Check if the Lat, Lng and UserLogin are in the JSON Data
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
        "Had LatLng Entry for $CustomerUser->{UserLogin} after switching SysConfig to show all Ticket Customers",
    );
}

1;
