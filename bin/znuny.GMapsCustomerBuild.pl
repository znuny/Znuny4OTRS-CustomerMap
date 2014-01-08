#!/usr/bin/perl -w
# --
# bin/znuny.GMapsCustomerBuild.pl - create customer/ticket address geo tag pool
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';

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
    print "znuny.GMapsCustomerBuild.pl - geo data collector\n";
    print "Copyright (C) 2014 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.GMapsCustomerBuild.pl [-f force]\n";
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
    print "NOTICE: znuny.GMapsCustomerBuild.pl is already running (use '-f 1' if you want to start it ";
    print "forced)!\n";
    exit 1;
}
elsif ( $Opts{f} && !$CommonObject{PIDObject}->PIDCreate( Name => 'GMapsCustomer' ) ) {
    print "NOTICE: znuny.GMapsCustomerBuild.pl is already running but is starting again!\n";
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
