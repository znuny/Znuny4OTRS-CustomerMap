# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ZnunyCustomerMap;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # Customer map
    $Self->{Translation}->{'Customer map'}                    = 'Kundenkarte';
    $Self->{Translation}->{'Loading...'}                      = 'Laden...';
    $Self->{Translation}->{'The map has not been loaded.'}    = 'Die Karte wurde nich geladen.';
    $Self->{Translation}->{'Load map.'}                       = 'Karte laden.';
    $Self->{Translation}->{'Customer map is not configured.'} = 'Kundenkarte ist nicht konfiguriert.';
    $Self->{Translation}->{'Make sure that UserStreet, UserCity and UserCountry are configured in SysConfig option Znuny::CustomerMap::CustomerDataAttributes and used as attributes in your customer user mapping config.'}
        = 'Stellen Sie sicher, dass UserStreet, UserCity und UserCountry in der SysConfig-Option Znuny::CustomerMap::CustomerDataAttributes und in Ihrem Kundenbenutzer-Mapping konfiguriert sind.';
    $Self->{Translation}->{'Execute "%s" to generate geo location data for your customers.'}
        = 'Führen Sie "%s" aus, um die Geodaten für die Standorte Ihrer Kunden zu generieren.';
    $Self->{Translation}->{'Reload this page and check if the customer map is being shown.'}
        = 'Laden Sie diese Seite neu und prüfen Sie, ob die Kundenkarte nun angezeigt wird.';

    # SysConfig
    $Self->{Translation}->{'Parameters for the customer map dashboard backend.'}
        = 'Parameter für das Customer-Map-Dashboard-Backend.';
    $Self->{Translation}->{'Select which customers will be shown on the map.'}
        = 'Wählen Sie aus, welche Kunden auf der Karte angezeigt werden sollen.';
    $Self->{Translation}->{'All customers assigned to a ticket'}
        = 'Alle Kunden, die einem Ticket zugewiesen';
    $Self->{Translation}->{'Only customers with open tickets'}
        = 'Nur Kunden, die offenen Tickets zugewiesen sind';
    $Self->{Translation}->{'Attributes used to get geo data for customer locations.'}
        = 'Attribute, um Geodaten für Kundenstandorte abzufragen.';
    $Self->{Translation}->{'Required attributes used to get geo data for customer locations.'}
        = 'Benötigte Attribute, um Geodaten für Kundenstandorte abzufragen.';
    $Self->{Translation}->{'Updates geo data for the customer map.'}
        = 'Aktualisiert Geodaten für die Kundenkarte.';



    $Self->{Translation}->{'Parameters for the dashboard backend. "Group" are used to restriced access to the plugin (e. g. Group: admin;group1;group2;). "Default" means if the plugin is enabled per default or if the user needs to enable it manually. "CacheTTL" means the cache time in minutes for the plugin.'}
        = 'Parameter für das Dashboard Backend. "Group" ist verwendet um den Zugriff auf das Plugin einzuschränken (z. B. Group: admin;group1;group2;). ""Default" bedeutet ob das Plugin per default aktiviert ist oder ob dies der Anwender manuell machen muss. "CacheTTL" ist die Cache-Zeit in Minuten nach der das Plugin erneut aufgerufen wird.';

    $Self->{Translation}->{'Frontend module registration for the AgentCustomerMap object in the agent interface.'}
        = 'Frontendmodul-Registration des AgentCustomerMap-Objekts im Agent-Interface.';
    $Self->{Translation}->{'Required API key for using Google Maps and Geocoding API.'} = 'Erforderlicher API-Schlüssel für die Verwendung von Google Maps und der Geokodierungs-API.';
    $Self->{Translation}->{'Loader module registration for the agent interface.'} = 'Loadermodul Registrierung für die Agentenschnittstelle.';
    $Self->{Translation}->{'Frontend module registration for the agent interface.'} = 'Frontend-Modulregistrierung für die Agentenschnittstelle.';
    $Self->{Translation}->{'Back'} = 'zurück';

    return 1;
}

1;
