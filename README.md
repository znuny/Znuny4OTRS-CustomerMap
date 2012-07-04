Google Maps Integration
=======================
With the Google Maps integration you will be able to see all customer on a map (customers with open tickets marked in a extra color). The map is available in Dashboard and also as an own dedicated one large page map (just click on “more” in dashboard).

1) Installation
===============
Download the package and install it via admin interface -> package manager.

2) Configuration
================
You need to have customer sources with the following attributes the let the extension work well.

UserStreet
UserCity
UserCountry

Configured in your CustomerUserMap (just take a look in your Kernel/Config.pm to check if you use them).

3) Build geo location data of your customer records
===================================================
Just execute the following cmd program to build your geo location database. You also can do this by using var/cron/customermap cron job to build it automatically.

shell> bin/otrs.GMapsCustomerBuild.pl
NOTICE: Done (wrote 209 records).
shell>

4) Check if it is working
=========================
Go to the dashboard, activate the widget “Customer Map” and check if you see your customers on the map. 

Enjoy the inspiration how to use this new kind of view (e. g. for optimizing your travel routes). Many new ideas coming by just watching this now extension.

Prerequisite
* OTRS 3.0
* OTRS 3.1

Commercial Support
==================
For this extention and for OTRS in gerneral visit http://znuny.com. Looking forward to hear from you!

Enjoy!

 Your Znuny Team!
 http://znuny.com

