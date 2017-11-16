#Customer overview on a map

This package extends the OTRS dashboard by displaying customers on a map (Google Maps).
This map displays the locations of customers for whom open tickets exist. Alternatively, this can be extended to all (not only open) tickets.

## Configuration

To display customer locations it is necessary to have a Google Maps Browser API key.
This can be obtained at https://developers.google.com/maps/documentation/javascript/get-api-key

This key must then be inserted in the SysConfig option `DashboardBackend####0001-CustomerMap` in the configuration field `MapsURL` instead of `MyGoogleMapsAPIKEY`.

## Determine the coordinates of the customer's locations

The OTRS daemon must be running to convert the address data into geocoordinates. It carries out the update daily at 3:45 a. m.

If you want to change this time, you can do so in the SysConfig option `Daemon:: SchedulerCronTaskManager::Task####UpdateCustomerMap` under "Schedule".

"Schedule" consists of five configuration options, as with Cron.

The first one is for minutes.
Examples:
`05` to run the update five minutes after every full hour.

``*` to run the update every minute.

`*/10` to run the update every ten minutes (each with a number of minutes divisible by ten without residual value), i. e.: 00,: 10,: 20,: 30,: 40,: 50 o' clock.

Possible values: `0-59` and `*`.

The second option stands for hours. Possible values: `0-23` and `*`.

The third option stands for the day of a month. Possible values: `1-31` and `*`.

The fourth option is for the month. Possible values: `1-12` and `*`.

The fifth option stands for the day of the week. Possible values: `0-6` and `*` where `0` represents Sunday and `6` Saturday.

In order for the conversion to be carried out correctly, it is necessary to
enter at least the following attributes in the customer mapping:

 - UserCity
 - UserStreet (optional)
 - UserCountry

If these attributes do not correspond to yours, they can be adjusted via SysConfig.
Hint:
Requests to the Google Geocoding API are limited to about 2000 per day.

The conversion can be done manually from the OTRS console:

```
    shell> bin/otrs.Console.pl Znuny::CustomerMap::Build
    NOTICE: Done (red 209 records).
    shell>
```

## Additional SysConfig options

 Znuny4OTRS::CustomerMap::CustomerSelection
 Znuny4OTRS::CustomerMap::CustomerDataAttributes
 Znuny4OTRS::CustomerMap::RequiredCustomerDataAttributes

## Note on displaying customers who have not yet had a ticket
Since the CustomerUserList function, which retrieves all customers from the database (see Git Commit](https://github.com/OTRS/otrs/commit/3a59683b3cd8cf5c1008150706d23677116736fc)), has been removed from OTRS, it is not possible to display customers without ticket allocation on the map.
