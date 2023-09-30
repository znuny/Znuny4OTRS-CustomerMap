# Configuration

To display customer locations it is necessary to have a Google Maps Browser API key.
This key must then be inserted in the SysConfig option `Znuny::CustomerMap::GoogleAPIKey`.

## Determine the coordinates of the customer's locations

The Znuny daemon must be running to convert the address data into geocoordinates. It carries out the update daily at 3:45 a. m.

If you want to change this time, you can do so in the SysConfig option `Daemon:: SchedulerCronTaskManager::Task####UpdateCustomerMap` under "Schedule".

In order for the conversion to be carried out correctly, it is necessary to
enter at least the following attributes in the customer mapping:

 - UserCity
 - UserStreet (optional)
 - UserCountry

If these attributes do not correspond to yours, they can be adjusted via SysConfig.
Hint:
Requests to the Google Geocoding API are limited to about 2000 per day.
The configured fields will be sent as a combined address string to Google to retrieve location data.

This can also be done manually as the Znuny user from the console:

```
    shell> bin/znuny.Console.pl Znuny::CustomerMap::Build
    NOTICE: Done (wrote 209 records).
    shell>
```

## System Configuration settings

### Znuny::CustomerMap::GoogleAPIKey

In this setting you have to enter the API key which you can get via the link https://developers.google.com/maps/documentation/javascript/get-api-key. Without this API key, use of the addon is not possible.

### Znuny::CustomerMap::CustomerDataAttributes

This determines from which attributes of your customer user configuration (CustomerUser) the information necessary for the determination of the coordinates is obtained. Please enter the appropriate name from the first column of the mapping as a value. Please leave the names of the keys unchanged.

### Znuny::CustomerMap::RequiredCustomerDataAttributes

These attributes are at least required to determine the coordinates to an address.

### Znuny::CustomerMap::CustomerSelection

This setting determines whether only the locations of the customers with open tickets should be displayed, or those of the customers to whom also have closed tickets.

### Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap

"Schedule" consists of five configuration options, as with Cron.

The first one is for minutes.
Examples:
`05` to run the update five minutes after every full hour.

`*` to run the update every minute.

`*/10` to run the update every ten minutes (each with a number of minutes divisible by ten without residual value), i. e.: 00,: 10,: 20,: 30,: 40,: 50 o' clock.

Possible values: `0-59` and `*`.

The second option stands for hours. Possible values: `0-23` and `*`.

The third option stands for the day of a month. Possible values: `1-31` and `*`.

The fourth option is for the month. Possible values: `1-12` and `*`.

The fifth option stands for the day of the week. Possible values: `0-6` and `*` where `0` represents Sunday and `6` Saturday.

## Note
Since the CustomerUserList function, which retrieves all customers from the database (see Git Commit](https://github.com/znuny/Znuny/commit/3a59683b3cd8cf5c1008150706d23677116736fc)), has been removed from Znuny, it is not possible to display customers without ticket allocation on the map.
