# --
# Kernel/System/GMaps.pm - lib for gmaps
# Copyright (C) 2001-2011 Martin Edenhofer, http://edenhofer.de/
# --
# $Id: $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GMaps;

use strict;
use warnings;

use Kernel::System::WebUserAgent;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.110 $) [1];

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

    # check needed objects
    for (qw(DBObject ConfigObject LogObject MainObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    # config
    $Self->{GeocodingURL} = 'http://maps.google.com/maps/geo?';

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

    for (qw(Query)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    my $WebUserAgentObject = Kernel::System::WebUserAgent->new(
        DBObject     => $Self->{DBObject},
        ConfigObject => $Self->{ConfigObject},
        LogObject    => $Self->{LogObject},
        MainObject   => $Self->{MainObject},
    );

    my $URL = $Self->{GeocodingURL} . 'q=' . $Param{Query} . '&output=csv';

    my %Response = $WebUserAgentObject->Request(
        URL => $URL,
    );

    return if !$Response{Content};

    my @Data = split /,/, ${ $Response{Content} };

    return (
        Status    => $Data[0],
        Accuracy  => $Data[1],
        Latitude  => $Data[2],
        Longitude => $Data[3],
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.12 $ $Date: 2009/04/17 08:36:44 $

=cut
