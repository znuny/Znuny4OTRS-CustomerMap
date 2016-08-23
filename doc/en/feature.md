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

Please make sure the OTRS Daemon is running. It will take care of updating the Map every day at 3:45 in the morning.

If you want to change that Time, please visit the SysConfig Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap and change the Schedule part there.

Like in Cron it consists of 5 config options.

First stands for minutes.
Examples:
05
for executing at 5 minutes past full hour.

*
for executing every minute.

*/10
for executing every 10 minutes

Possible Values: 0-59 and *

Second stands for hour. Possible Values: 0-23 and *

Third stands for day of a month. Possible Values: 1-31 and *

Fourth stands for month. Possible Values: 1-12 and *

Fifth stands for day of the week. Possible Values: 0-6  and * where 0 is Sunday, 6 is Saturday.

Your customer data needs the following attributes to be able to determine the geo location of a customer:

 - UserCity
 - UserStreet *optional
 - UserCountry

Do you use other attributes? No problem, just change the settings via SysConfig as needed.
Reminder:
There's a daily limit for requests against Google Geocoding API.

Doing the location update manually:

    shell> bin/otrs.Console.pl Znuny::CustomerMapBuild
    NOTICE: Done (wrote 209 records).
    shell>

## Sysconfig

 - Znuny4OTRSCustomerMapOnlyOpenTickets
 - Znuny4OTRSCustomerMapCustomerDataAttributes
 - Znuny4OTRSCustomerMapRequiredCustomerDataAttributes

## Note for displaying customers that don't have Tickets yet
OTRS removed the CustomerUserList function that queried all customer users from the database for one of the next major versions ([siehe Git Commit](https://github.com/OTRS/otrs/commit/3a59683b3cd8cf5c1008150706d23677116736fc)). That's why we removed the functionality and reduced it to show only customers which had at least a Ticket.