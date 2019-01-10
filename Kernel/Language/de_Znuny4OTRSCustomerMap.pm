# --
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Znuny4OTRSCustomerMap;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # SysConfig
    $Self->{Translation}->{'Required API key for using Google Maps and Geocoding API.'} = 'Erforderlicher API-Schlüssel für die Verwendung von Google Maps und der Geokodierungs-API.';

    $Self->{Translation}->{'Customer map'}                    = 'Kundenkarte';
    $Self->{Translation}->{'Loading...'}                      = 'Laden...';
    $Self->{Translation}->{'The map has not been loaded.'}    = 'Die Karte wurde nich geladen.';
    $Self->{Translation}->{'Load map.'}                       = 'Karte laden.';
    $Self->{Translation}->{'Customer map is not configured.'} = 'Kundenkarte ist nicht konfiguriert.';

    $Self->{Translation}->{'Make sure that UserStreet, UserCity and UserCountry are configured in SysConfig option Znuny4OTRS::CustomerMap::CustomerDataAttributes and used as attributes in your customer user mapping config.'} = 'Stellen Sie sicher, dass UserStreet, UserCity und UserCountry in der SysConfig-Option Znuny4OTRS::CustomerMap::CustomerDataAttributes und in Ihrem Kundenbenutzer-Mapping konfiguriert sind.';
    $Self->{Translation}->{'Execute \"%s\" to generate geo location data for your customers.'} = 'Führen Sie "%s" aus, um die Geodaten für die Standorte Ihrer Kunden zu generieren.';
    $Self->{Translation}->{'Reload this page and check if the customer map is being shown.'} = 'Laden Sie diese Seite neu und prüfen Sie, ob die Kundenkarte nun angezeigt wird.';

    $Self->{Translation}->{'Parameters for the dashboard backend. "Group" are used to restriced access to the plugin (e. g. Group: admin;group1;group2;). "Default" means if the plugin is enabled per default or if the user needs to enable it manually. "CacheTTL" means the cache time in minutes for the plugin.'} = 'Parameter für das Dashboard Backend. "Group" ist verwendet um den Zugriff auf das Plugin einzuschränken (z. B. Group: admin;group1;group2;). ""Default" bedeutet ob das Plugin per default aktiviert ist oder ob dies der Anwender manuell machen muss. "CacheTTL" ist die Cache-Zeit in Minuten nach der das Plugin erneut aufgerufen wird.';

    $Self->{Translation}->{'Frontend module registration for the AgentCustomerMap object in the agent interface.'} = 'Frontendmodul-Registration des AgentCustomerMap-Objekts im Agent-Interface.';

    $Self->{Translation}->{'Attributes used to get geolocation.'}          = 'Attribute, die zum Abrufen der Geolocation verwendet werden.';
    $Self->{Translation}->{'Show only open Tickets in customer map.'}      = 'Nur offene Tickets in der Kundenkarte anzeigen.';
    $Self->{Translation}->{'Updates the customer map based on addresses.'} = 'Aktualisiert die Kundenkarte basierend auf Adressen.';
    $Self->{Translation}->{'Agent CustomerMap'}                            = 'Agent CustomerMap';

    return 1;
}

1;
