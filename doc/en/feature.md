# Customer Map

This package provides you a customer map based on Google Maps on your OTRS dashboard.
The locations show on this map representing customer with open tickets in your system.
Of course, you can adjust settings via SysConfig to show all Customers that ever had a Ticket.

# Configuration

To display customer locations, its obligatory to have a GoogleMaps Browser-API-Key.

If you don't have one yet, you can obtain it via:

https://developers.google.com/maps/documentation/javascript/get-api-key

This Key has to be inserted in the SysConfig Option:
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
![GoogleMapsAPIKey](doc/de/images/MapKeyInsert.jpg)

# Determin customer locations

You'll find a script in the bin folder which is needed to fetch the coordinates of you customer.
Please run the script on regular basis.

Your customer data needs the following attributes to be able to determine the geo location of a customer:

 - UserCity
 - UserStreet *optional
 - UserCountry

Do you use other attributes? No problem, just change the settings via SysConfig as needed.
Reminder:
There's a daily limit for requests against Google Geocoding API.
The configured fields will be sent as a combined address string to Google to retrieve location data.

Doing the location update manually:

    shell> bin/znuny.GMapsCustomerBuild.pl
    NOTICE: Done (wrote 209 records).
    shell>

As an alternative add the provided script to your OTRS crontab. The needed entry is located in var/cron/customermap

## SysConfig

 - Znuny4OTRSCustomerMapOnlyOpenTickets
 - Znuny4OTRSCustomerMapCustomerDataAttributes
 - Znuny4OTRSCustomerMapRequiredCustomerDataAttributes

## Note for displaying customers that don't have Tickets yet
OTRS removed the CustomerUserList function that queried all customer users from the database for one of the next major versions ([siehe Git Commit](https://github.com/OTRS/otrs/commit/3a59683b3cd8cf5c1008150706d23677116736fc)). That's why we removed the functionality and reduced it to show only customers which had at least a Ticket.
