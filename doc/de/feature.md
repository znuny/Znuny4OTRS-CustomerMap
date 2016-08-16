# Customer Map

Dieses Paket enthält erweitert das OTRS Dashboard um eine Kundenkarte (Google Maps).
Auf dieser Karte werden Standorte von Kunden angezeigt, welche über offene Tickets im 
System verfügen. Diese Einstellung kann über die Sysconfig angepasst werden. 

# Konfiguration

Um Kundenstandorte anzuzeigen, ist es notwendig einen GoogleMaps Browser-API-Key zu besitzen.

Sollten Sie noch keinen ihr Eigen nennen, können Sie diesen unter:

https://developers.google.com/maps/documentation/javascript/get-api-key

anfordern.

Dieser Key ist dann in der SysConfig Option
```
Znuny4OTRS-CustomerMap->Frontend::Agent::Dashboard
```
im Konfigurationsfeld:
```
MapsURL
```
anstelle von
```
MyGoogleMapsAPIKEY
```
einzufügen.

Siehe:
![GoogleMapsAPIKey](doc/de/images/MapKeyInsert.jpg)

# Koordinaten der Kundenstandorte ermitteln

Um die Adressdaten in Geokoordinaten umzuwandeln, wird ein Skript benötigt welches sich im bin/
Verzeichnis befindet. Damit die Umwandlung korrekt durchgeführt werden kann, ist es notwendig
mindestens folgende Attribute im Kunden Mapping eingetragen zu haben:

 - UserCity
 - UserStreet *optional
 - UserCountry

Sollten diese Attribute nicht Ihren entsprechen, können diese über die Sysconfig angepasst werden.
Hinweis:
Die Anfragen an der Google Geocoding API sind auf ca 2000 Anfragen pro Tag limittiert.

Das Umwandeln kann über die Konsole manuell ausgeführt werden:

    shell> bin/znuny.GMapsCustomerBuild.pl
    NOTICE: Done (wrote 209 records).
    shell>

Alternativ ist es möglich das Skript in die Crontab zu übernehmen. Die passende Vorlage
findet sich unter var/cron/customermap

## Sysconfig

 - Znuny4OTRSCustomerMapOnlyOpenTickets
 - Znuny4OTRSCustomerMapCustomerDataAttributes
 - Znuny4OTRSCustomerMapRequiredCustomerDataAttributes

