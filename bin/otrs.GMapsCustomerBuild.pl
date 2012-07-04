#!/usr/bin/perl -w
# --
# bin/otrs.GMapsCustomerBuild.pl - create customer/ticket address geo tag pool
# Copyright (C) 2001-2011 Martin Edenhofer, http://edenhofer.de/
# Copyright (C) 2012 Znuny GmbH, http://znuny.com/
# --
# $Id: $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';

use vars qw($VERSION);
$VERSION = qw($Revision: 1.36 $) [1];

use Getopt::Std;
use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Main;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::Log;
use Kernel::System::PID;
use Kernel::System::GMapsCustomer;

# get options
my %Opts;
getopt( 'hqtdf', \%Opts );
if ( $Opts{h} ) {
    print "GMapsCustomerBuild.pl <Revision $VERSION> - geo data collector\n";
    print "Copyright (C) 2001-2011 Martin Edenhofer, http://edenhofer.de/\n";
    print "usage: otrs.GMapsCustomerBuild.pl [-f force]\n";
    exit 1;
}
if ( !$Opts{d} ) {
    $Opts{d} = 0;
}

# create common objects
my %CommonObject;
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-GMapsCustomerBuild',
    %CommonObject,
);
$CommonObject{MainObject} = Kernel::System::Main->new(%CommonObject);
$CommonObject{TimeObject} = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject}   = Kernel::System::DB->new(%CommonObject);
$CommonObject{PIDObject}  = Kernel::System::PID->new(%CommonObject);

# create pid lock
if ( !$Opts{f} && !$CommonObject{PIDObject}->PIDCreate( Name => 'GMapsCustomer' ) ) {
    print "NOTICE: otrs.GMapsCustomer.pl is already running (use '-f 1' if you want to start it ";
    print "forced)!\n";
    exit 1;
}
elsif ( $Opts{f} && !$CommonObject{PIDObject}->PIDCreate( Name => 'GMapsCustomer' ) ) {
    print "NOTICE: otrs.GMapsCustomer.pl is already running but is starting again!\n";
}

# common objects
$CommonObject{GMapsCustomer} = Kernel::System::GMapsCustomer->new(
    %CommonObject,
);
my $Count = $CommonObject{GMapsCustomer}->DataBuild();
if ($Count) {
    print "NOTICE: Done (wrote $Count records).\n";
}
else {
    print STDERR "ERROR: Failed!\n";
}

# delete pid lock
$CommonObject{PIDObject}->PIDDelete( Name => 'GMapsCustomer' );
exit 0;
