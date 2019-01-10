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

    $Self->{Translation}->{'Parameters for the dashboard backend. "Group" are used to restriced access to the plugin (e. g. Group: admin;group1;group2;). "Default" means if the plugin is enabled per default or if the user needs to enable it manually. "CacheTTL" means the cache time in minutes for the plugin.'}
        = 'Parameter für das Dashboard Backend. "Group" ist verwendet um den Zugriff auf das Plugin einzuschränken (z. B. Group: admin;group1;group2;). ""Default" bedeutet ob das Plugin per default aktiviert ist oder ob dies der Anwender manuell machen muss. "CacheTTL" ist die Cache-Zeit in Minuten nach der das Plugin erneut aufgerufen wird.';

    $Self->{Translation}->{'Frontend module registration for the AgentCustomerMap object in the agent interface.'}
        = 'Frontendmodul-Registration des AgentCustomerMap-Objekts im Agent-Interface.';
    return 1;
}

1;
