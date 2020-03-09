# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::CustomerMap::Build;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::GMapsCustomer',
    'Kernel::System::PID',
    'Kernel::System::Log',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description("Collects geo data for customer map.\nCopyright (C) 2012-2020 Znuny GmbH, http://znuny.com/");

    $Self->AddOption(
        Name        => 'force-pid',
        Description => "Start geodata collector even if another process is still running.",
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'debug',
        Description => "Print debug info to the OTRS log.",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub PreRun {
    my ($Self) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $PIDObject = $Kernel::OM->Get('Kernel::System::PID');

    my $PIDCreated = $PIDObject->PIDCreate(
        Name  => $Self->Name(),
        Force => $Self->GetOption('force-pid'),
        TTL   => 3 * 24 * 60 * 60,
    );
    if ( !$PIDCreated ) {
        my $Error = "Unable to register the process in the database. Is another process still running?\n"
            . "You can use --force-pid to override this check.\n";
        die $Error;
    }

    return if !$Self->GetOption('debug');

    $LogObject->Log(
        Priority => 'debug',
        Message  => 'Znuny4OTRS-CustomerMap: Build (' . $Self->Name() . ') started.',
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $GMapsObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');
    $Self->Print("$Self->{Description}\n");
    $Self->Print("<yellow>Builds customer maps...</yellow>\n\n");

    my $Count = $GMapsObject->DataBuild();
    if ( defined $Count ) {
        $Self->Print("\n <green>Done (wrote $Count records).</green>\n");
    }
    else {
        $Self->Print("\n<red>ERROR: Failed!</red>\n");
    }

    return $Self->ExitCodeOk();
}

sub PostRun {
    my ($Self) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $PIDObject = $Kernel::OM->Get('Kernel::System::PID');

    if ( $Self->GetOption('debug') ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => 'Znuny4OTRS-CustomerMap: Build (' . $Self->Name() . ') stopped.',
        );
    }

    my $Result = $PIDObject->PIDDelete( Name => $Self->Name() );
    return $Result;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
