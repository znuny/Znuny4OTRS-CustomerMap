# --
# Kernel/System/GMaps.pm - lib for gmaps
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# Copyright (C) 2013 Juergen Sluyterman, http://www.rsag.de/
# --

package Kernel::System::GMaps;

use strict;
use warnings;

use Kernel::System::WebUserAgent;
use utf8;
our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Encode',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::JSON',
    'Kernel::System::WebUserAgent',
);

=head1 NAME

Kernel::System::GMaps - a google maps lib

=head1 SYNOPSIS

All google maps functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::WebUserAgent;

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
    my $GMapsObject = Kernel::System::GMaps->new(
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

    # config
    $Self->{GeocodingURL} = 'http://maps.googleapis.com/maps/api/geocode/json?';

    return $Self;
}

=item Geocoding()

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
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    for (qw(Query)) {
        if ( !$Param{$_} ) {
            $LogObject->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }


    my $URL = $Self->{GeocodingURL} . 'address=' . $Param{Query} . '&sensor=false';

    my %Response = $WebUserAgentObject->Request(
        URL => $URL,
    );
    return if !$Response{Content};

    my $JSONResponse = ${ $Response{Content} };
    my $Hash = $JSONObject->Decode(Data => $JSONResponse)

    if ( !$Hash || !$Hash->{status} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't process '$URL' got no json data back! '$JSONResponse'",
        );
        return;
    }
    my $Status    = $Hash->{status};
    if ( lc($Status) ne 'ok' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Can't process '$URL', status '$Status'",
        );
        return;
    }
    return if !$Hash->{results};
    return if !$Hash->{results}->[0];
    my $Accuracy  = $Hash->{results}->[0]->{geometry}->{location_type};
    my $Longitude = $Hash->{results}->[0]->{geometry}->{location}->{lng};
    my $Latitude  = $Hash->{results}->[0]->{geometry}->{location}->{lat};

    return (
        Status    => $Status,
        Accuracy  => $Accuracy,
        Latitude  => $Latitude,
        Longitude => $Longitude,
    );
}

1;
