# Customer Map

This package provides you a customer map based on Google Maps on your OTRS dashboard.
The locations show on this map representing customer with open tickets in your system.
Of course, you can adjust settings via SysConfig.

You'll find a script in the bin folder which is needed to fetch the coordinates of you customer.
Please run the script on regular basis.
Your customer data needs the following attributes to be able to determine the geo location of a customer:

 - UserCity
 - UserStreet *optional
 - UserCountry

Do you use other attributes? No problem, just change the settings via SysConfig as needed.
Reminder:
There's a daily limit for requests against Google Geocoding API.

Doing the location update manually:

    shell> bin/znuny.GMapsCustomerBuild.pl
    NOTICE: Done (wrote 209 records).
    shell>

As an alternative add the provided script to your OTRS crontab. The needed entry is located in var/cron/customermap

## Sysconfig

 - Znuny4OTRSCustomerMapOnlyOpenTickets
 - Znuny4OTRSCustomerMapCustomerDataAttributes
 - Znuny4OTRSCustomerMapRequiredCustomerDataAttributes

