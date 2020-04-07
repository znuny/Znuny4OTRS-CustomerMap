# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use Kernel::System::VariableCheck qw(:all);

use vars (qw($Self));

my $SeleniumObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');
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

$Self->True(
    $ENV{'GOOGLE_APIKEY'},
    "GOOGLE_APIKEY $ENV{GOOGLE_APIKEY}"
);

$ConfigObject->Set(
    Key   => 'Znuny4OTRS::CustomerMap::GoogleAPIKey',
    Value => $ENV{'GOOGLE_APIKEY'},
);


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
for my $CustomerUser (@CustomerTemplate) {
    my %CustomerCreated;
    my $CustomerUserLogin = $ZnunyHelperObject->_CustomerUserCreateIfNotExists( %{$CustomerUser} );

    $Self->True(
        $CustomerUserLogin,
        "Created CustomerUserLogin $CustomerUserLogin.",
    );

    %CustomerCreated = (
        %{$CustomerUser},
        CustomerLogin => $CustomerUserLogin,
    );

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
    push @CustomerUsers, \%CustomerCreated;
}

$GMapsCustomerObject->DataBuild();

# store test function in variable so the Selenium object can handle errors/exceptions/dies etc.
my $SeleniumTest = sub {

    # initialize Znuny4OTRS Helpers and other needed objects
    my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

    # set up a full featured test environment
    my $TestEnvironmentData = $HelperObject->SetupTestEnvironment();

    # create test user and login
    my %TestUser = $SeleniumObject->AgentLogin(
        Groups => [ 'admin', 'users' ],
    );

    $SeleniumObject->AgentInterface(
        Action      => 'AgentCustomerMap',
        WaitForAJAX => 0,
    );

    sleep 3;
    $SeleniumObject->PageContains(
        String  => 'gm-style',
        Message => "Page contains 'gm-style'"
    );
};

# finally run the test(s) in the browser
$SeleniumObject->RunTest($SeleniumTest);

1;
