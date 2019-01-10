# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# Copyright (C) 2013 Juergen Sluyterman, http://www.rsag.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::GMaps;

use strict;
use warnings;

use utf8;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::WebUserAgent',
);

=head1 NAME

Kernel::System::GMaps - a google maps lib

=head1 SYNOPSIS

All google maps functions.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    my $GMapsObject   = $Kernel::OM->Get('Kernel::System::GMaps');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    $Self->{GeocodingURL} = 'https://maps.googleapis.com/maps/api/geocode/json?';

    return $Self;
}

=head2 Geocoding()

return the content of requested URL

    my %Response = $GMapsObject->Geocoding(
        Query => 'some location, country',
    );

returns

    %Response = (
        Status    => 200,
        Accuracy  => 1,
    );

see also: http://code.google.com/apis/maps/documentation/geocoding/


=cut

sub Geocoding {
    my ( $Self, %Param ) = @_;

    my $WebUserAgentObject = $Kernel::OM->Get('Kernel::System::WebUserAgent');
    my $JSONObject         = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');

    NEEDED:
    for my $Needed (qw(Query)) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed!"
        );
        return;
    }

    my $APIKey = $ConfigObject->Get('Znuny4OTRS::CustomerMap::GoogleAPIKey');
    my $URL    = $Self->{GeocodingURL} . 'address=' . $Param{Query} . '&sensor=false&key=' . $APIKey;

    my %Response = $WebUserAgentObject->Request(
        URL => $URL,
    );
    return if !%Response || !$Response{Content};

    my $GeocodingJSONResponse = ${ $Response{Content} };
    my $GeocodingData = $JSONObject->Decode( Data => $GeocodingJSONResponse );

    if (
        !IsHashRefWithData($GeocodingData)
        || !$GeocodingData->{status}
        )
    {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't process '$URL',  got no JSON data back! '$GeocodingJSONResponse'.",
        );
        return;
    }
    my $Status = $GeocodingData->{status};
    if ( lc($Status) ne 'ok' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't process '$URL', status '$Status'.",
        );
        return;
    }
    return if !$GeocodingData->{results};
    return if !$GeocodingData->{results}->[0];

    my $Accuracy  = $GeocodingData->{results}->[0]->{geometry}->{location_type};
    my $Longitude = $GeocodingData->{results}->[0]->{geometry}->{location}->{lng};
    my $Latitude  = $GeocodingData->{results}->[0]->{geometry}->{location}->{lat};

    return (
        Status    => $Status,
        Accuracy  => $Accuracy,
        Latitude  => $Latitude,
        Longitude => $Longitude,
    );
}
1;
