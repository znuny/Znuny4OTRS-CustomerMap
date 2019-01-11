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

my $GMapsObject  = $Kernel::OM->Get('Kernel::System::GMaps');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

$Self->True(
    $ENV{GOOGLE_APIKEY},
    "GOOGLE_APIKEY $ENV{GOOGLE_APIKEY}"
);

$ConfigObject->Set(
    Key   => 'Znuny4OTRS::CustomerMap::GoogleAPIKey',
    Value => $ENV{GOOGLE_APIKEY},
);

my $Query    = 'Berlin, Deutschland, Marienstraße 11';
my %Response = $GMapsObject->Geocoding(
    Query => $Query,
);

$Self->IsDeeply(
    \%Response,
    {
        Latitude  => '52.5219195',
        Status    => 'OK',
        Longitude => '13.3826705',
        Accuracy  => 'ROOFTOP'
    },
    "Geocoding for $Query",
);

1;
