#!/usr/bin/perl
# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
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
    print "Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/\n";
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
if ( defined $Count ) {
    print "NOTICE: Done (wrote $Count records).\n";
}
else {
    print STDERR "ERROR: Failed!\n";
}

# delete pid lock
$PIDObject->PIDDelete( Name => 'GMapsCustomer' );
exit 0;
