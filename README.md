![Znuny logo](http://znuny.com/assets/images/logo_small.png)

Google Maps Integration
=======================
With the Google Maps integration you will be able to see all customers that ever had a ticket on a map (customers with open tickets are marked in an extra color). The map is available in Dashboard and also as an own dedicated one large page map (just click on “more” in dashboard).

<img src="https://raw.github.com/znuny/Znuny4OTRS-CustomerMap/master/doc/en/images/customermap.png" />

**Installation**

Download the package and install it via admin interface -> package manager or use Znuny4OTRS-Repo.


**Prerequisites**

- Znuny4OTRS-Repo

- OTRS 5

- Google Maps Browser-API-Key - can be optained from https://developers.google.com/maps/documentation/javascript/get-api-key

**Configuration**

The Google Maps API Key has to be inserted in the SysConfig Option:
```
Znuny4OTRS-CustomerMap->Frontend::Agent::Dashboard
```
at Key:
```
MapsURL
```
by replacing
```
MyGoogleMapsAPIKEY
```
with the API Key.

Like:
<img src="https://raw.github.com/znuny/Znuny4OTRS-CustomerMap/master/doc/en/images/MapKeyInsert.jpg" />

You need to have customer sources with the following attributes for the extension to work
UserStreet

UserCity

UserCountry

configured in your CustomerUserMap (just take a look in your Kernel/Config.pm to check out if you use them).
The configured fields will be sent as a combined address string to Google to retrieve location data.


**Build geo location data of your customer records**

Just execute the following console command build your geo location database.

    shell> bin/otrs.Console.pl Znuny::CustomerMapBuild
    NOTICE: Done (wrote 209 records).
    shell>

**Check if it is working**

Go to the dashboard, activate the widget “Customer Map” and check if you see your customers on the map.

Enjoy the inspiration how to use this new kind of view (e. g. for optimizing your travel routes).

**Download**

For download see [http://znuny.com/en/#!/addons](http://znuny.com/en/#!/addons)

**Commercial Support**

For this extension and for OTRS in general visit [http://znuny.com/](http://znuny.com/). Looking forward to hear from you!

Enjoy!

 Your Znuny Team!

 [http://znuny.com/](http://znuny.com/)
