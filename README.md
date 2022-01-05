![Znuny logo](https://www.znuny.com/assets/images/logo_small.png)


![Build status](https://badge.proxy.znuny.com/Znuny4OTRS-CustomerMap/rel-6_1)

Google Maps Integration
=======================
With the Google Maps integration you will be able to see all customers on a map that ever had a ticket (customers with open tickets are marked in an extra color). The map is available in the dashboard and also as a dedicated map on a large separate page (just click on “more” in dashboard).

<img src="https://raw.github.com/znuny/Znuny4OTRS-CustomerMap/rel-6_1/doc/en/images/customermap.png" />

**Prerequisites**

- Znuny 6.1
- Google Maps Browser-API-Key - can be obtained from https://developers.google.com/maps/documentation/javascript/get-api-key

**Installation**

Download the [package](https://addons.znuny.com/api/addon_repos/public/2107/latest) and install it via admin interface -> package manager.

**Configuration**

The Google Maps API Key has to be inserted in the SysConfig option:
```
DashboardBackend###0001-CustomerMap
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

You need to have customer sources with the following attributes for the extension to work:

* UserStreet
* UserCity
* UserCountry

configured in your customer user map (just take a look in your Kernel/Config.pm to check if you use them).
The configured fields will be sent as a combined address string to Google to retrieve location data.


**Build geo location data of your customer records**

Just execute the following console command to build your geo location database.

    shell> bin/otrs.Console.pl Znuny::CustomerMap::Build
    NOTICE: Done (wrote 209 records).
    shell>

**Check if it is working**

Go to the dashboard, activate the widget “Customer map” and check if you see your customers on the map.

Enjoy the inspiration how to use this new kind of view (e.g. for optimizing your travel routes).

**Download**

Download the [latest version](https://addons.znuny.com/api/addon_repos/public/2107/latest).

**Professional Support**

For this add-on and for Znuny in general visit [www.znuny.com](https://www.znuny.com). Looking forward to hear from you!

Enjoy!

Your Znuny Team!

[https://www.znuny.com](https://www.znuny.com)
