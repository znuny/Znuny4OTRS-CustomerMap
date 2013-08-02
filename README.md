![Znuny logo](http://znuny.com/assets/logo_small.png) 

Google Maps Integration
=======================
With the Google Maps integration you will be able to see all customers on a map (customers with open tickets are marked in an extra color). The map is available in Dashboard and also as an own dedicated one large page map (just click on “more” in dashboard).

<img src="https://raw.github.com/znuny/Znuny4OTRS-CustomerMap/master/screenshots/customermap.png" />

**Installation**

Download the package and install it via admin interface -> package manager or use Znuny4OTRS-Repo.


**Prerequisites**

- Znuny4OTRS-Repo

- OTRS 3.0

- OTRS 3.1

- OTRS 3.2


**Configuration**

You need to have customer sources with the following attributes for the extension to work
UserStreet

UserCity

UserCountry

configured in your CustomerUserMap (just take a look in your Kernel/Config.pm to check out if you use them).

**Build geo location data of your customer records**

Just execute the following cmd program to build your geo location database. You may also do this by using var/cron/customermap cron job to build it automatically.

    shell> bin/otrs.GMapsCustomerBuild.pl
    NOTICE: Done (wrote 209 records).
    shell>

**Check if it is working**

Go to the dashboard, activate the widget “Customer Map” and check if you see your customers on the map. 

Enjoy the inspiration how to use this new kind of view (e. g. for optimizing your travel routes). 

**Download**

For download see [http://znuny.com/d/](http://znuny.com/d/)

**Commercial Support**

For this extension and for OTRS in general visit [http://znuny.com](http://znuny.com). Looking forward to hear from you!

Enjoy!

 Your Znuny Team!

 [http://znuny.com](http://znuny.com)

