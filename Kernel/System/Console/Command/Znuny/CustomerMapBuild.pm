# --
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny::CustomerMapBuild;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::GMapsCustomer',
    'Kernel::System::PID',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description("Geo data collector\nCopyright (C) 2012-2015 Znuny GmbH, http://znuny.com/");

    $Self->AddOption(
        Name        => 'force-pid',
        Description => "Start even if another process is still registered in the database.",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
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
    my $PIDObject = $Kernel::OM->Get('Kernel::System::PID');

    my $PIDCreated = $PIDObject->PIDCreate(
        Name  => $Self->Name(),
        Force => $Self->GetOption('force-pid'),
        TTL   => 60 * 60 * 24 * 3,
    );
    if ( !$PIDCreated ) {
        my $Error = "Unable to register the process in the database. Is another instance still running?\n";
        $Error .= "You can use --force-pid to override this check.\n";
        die $Error;
    }

    my $Debug = $Self->GetOption('debug');
    my $Name  = $Self->Name();

    if ($Debug) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => "Znuny4OTRS CustomerMapBuild ($Name) started.",
        );
    }

    return;

}

sub Run {
    my ( $Self, %Param ) = @_;

    my $GMapsObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');
    $Self->Print("\nGeo data collector\n");
    $Self->Print("\nCopyright (C) 2012-2015 Znuny GmbH, http://znuny.com/\n");
    $Self->Print("<yellow>Builds customer maps...</yellow>\n\n");

    my $Count = $GMapsObject->DataBuild();
    if ($Count) {
        $Self->Print("\n<green> Done (wrote $Count records).</green>\n");
    }
    else {
        $Self->Print("\n<red>ERROR: Failed!</red>\n");
    }


    return $Self->ExitCodeOk();
}

sub PostRun {
    my ($Self) = @_;

    my $Debug = $Self->GetOption('debug');
    my $Name  = $Self->Name();

    if ($Debug) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => "Znuny4OTRS CustomerMapBuild ($Name) stopped.",
        );
    }

    return $Kernel::OM->Get('Kernel::System::PID')->PIDDelete( Name => $Self->Name() );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
