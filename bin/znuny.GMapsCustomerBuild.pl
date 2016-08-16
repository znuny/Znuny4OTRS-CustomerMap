#!/usr/bin/perl
# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Getopt::Std;
use Kernel::System::ObjectManager;

# create common objects
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-znuny.GMapsCustomerBuild.pl',
    },
);

# get options
my %Opts;
getopt( 'hqtdf', \%Opts );
if ( $Opts{h} ) {
    print "znuny.GMapsCustomerBuild.pl - geo data collector\n";
    print "Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.GMapsCustomerBuild.pl [-f force]\n";
    exit 1;
}
if ( !$Opts{d} ) {
    $Opts{d} = 0;
}
my $PIDObject   = $Kernel::OM->Get('Kernel::System::PID');
my $GMapsObject = $Kernel::OM->Get('Kernel::System::GMapsCustomer');

# create pid lock
if ( !$Opts{f} && !$PIDObject->PIDCreate( Name => 'GMapsCustomer' ) ) {
    print "NOTICE: znuny.GMapsCustomerBuild.pl is already running (use '-f 1' if you want to start it ";
    print "forced)!\n";
    exit 1;
}
elsif ( $Opts{f} && !$PIDObject->PIDCreate( Name => 'GMapsCustomer' ) ) {
    print "NOTICE: znuny.GMapsCustomerBuild.pl is already running but is starting again!\n";
}

my $Count = $GMapsObject->DataBuild();
if ($Count) {
    print "NOTICE: Done (wrote $Count records).\n";
}
else {
    print STDERR "ERROR: Failed!\n";
}

# delete pid lock
$PIDObject->PIDDelete( Name => 'GMapsCustomer' );
exit 0;
