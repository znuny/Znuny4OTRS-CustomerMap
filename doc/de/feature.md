# Kundenübersicht auf einer Karte

Dieses Paket erweitert das OTRS-Dashboard um die Anzeige von Kunden auf einer Karte (Google Maps).
Auf dieser Karte werden Standorte von Kunden angezeigt, für die offene Ticket existieren. Alternativ kann dies auf alle (also nicht nur offene) Tickets ausgeweitet werden.

## Konfiguration

Um Kundenstandorte anzuzeigen ist es notwendig einen Google-Maps-Browser-API-Key zu besitzen.
Dieser kann unter `https://developers.google.com/maps/documentation/javascript/get-api-key` bezogen werden.

Dieser Key ist dann in der SysConfig-Option `DashboardBackend###0001-CustomerMap` im Konfigurationsfeld `MapsURL` anstelle von `MyGoogleMapsAPIKEY` einzufügen.

## Koordinaten der Kundenstandorte ermitteln

Der OTRS-Daemon muss laufen, um die Adressdaten in Geokoordinaten umzuwandeln. Er führt die Aktualisierung täglich um 3:45 Uhr aus.

Wenn Sie diese Uhrzeit ändern möchten, können Sie dies in der SysConfig-Option `Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap` unter "Schedule" machen.

"Schedule" besteht wie bei Cron aus fünf Konfigurationsoptionen.

Die erste steht für Minuten.
Beispiele:
`05` um das Update fünf Minuten nach jeder vollen Stunde auszuführen.

`*` um das Update jede Minute auszuführen.

`*/10` um das Update alle zehn Minuten (in jeder durch zehn ohne Restwert teilbaren Minutenzahl) auszuführen, sprich: :00, :10, :20, :30, :40, :50 Uhr.

Mögliche Werte: `0-59` sowie `*`.

Die zweite Option steht für Stunden. Mögliche Werte: `0-23` sowie `*`.

Die dritte Option steht für den Tag eines Monats. Mögliche Werte: `1-31` sowie `*`.

Die vierte Option steht für den Monat. Mögliche Werte: `1-12` sowie `*`.

Die fünfte Option steht für den Wochentag. Mögliche Werte: `0-6`  sowie `*` wobei `0` Sonntag und `6` Samstag repräsentieren.

Damit die Umwandlung korrekt durchgeführt werden kann, ist es notwendig
mindestens folgende Attribute im Customer-Mapping einzutragen:

 - UserCity
 - UserStreet (optional)
 - UserCountry

Sollten diese Attribute nicht Ihren entsprechen, können diese über die SysConfig angepasst werden.
Hinweis:
Die Anfragen an die Google-Geocoding-API sind auf ca. 2000 pro Tag limitiert.

Die Umwandlung kann über die OTRS-Konsole manuell ausgeführt werden:

```
    shell> bin/otrs.Console.pl Znuny4OTRS::CustomerMap::Build
    NOTICE: Done (wrote 209 records).
    shell>
```

## Weitere SysConfig-Optionen

 - Znuny4OTRS::CustomerMap::CustomerSelection
 - Znuny4OTRS::CustomerMap::CustomerDataAttributes
 - Znuny4OTRS::CustomerMap::RequiredCustomerDataAttributes

## Hinweis zur Darstellung von Kunden, die noch kein Ticket hatten
Da die CustomerUserList-Funktion, die sämtliche Kunden aus der Datenbank holt ([siehe Git Commit](https://github.com/OTRS/otrs/commit/3a59683b3cd8cf5c1008150706d23677116736fc)), aus OTRS entfernt wurde, können keine Kunden ohne Ticketzuordnung auf der Karte dargestellt werden.
