# Customer Map

Dieses Paket erweitert das OTRS Dashboard um eine Kundenkarte (Google Maps).
Auf dieser Karte werden Standorte von Kunden angezeigt, welche über offene Tickets im
System verfügen. Diese Einstellung kann über die Sysconfig angepasst werden.

Um die Adressdaten in Geokoordinaten umzuwandeln, versichern Sie sich bitte dass der OTRS Daemon läuft. Er führt die aktualisierung täglich um 03:45 Uhr durch.

Wenn Sie diese Uhrzeit ändern wollen, können Sie dies in der SysConfig Option Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap unter "Schedule" machen.

Schedule besteht wie bei Cron aus 5 konfigurationsoptionen.

Die erste steht für Minuten.
Beispiele:
05
um das Update 5 Minuten nach jeder vollen Stunde auszuführen.

*
um das Update jede Minute auszuführen.

*/10
um das Update alle 10 Minuten (in jeder durch 10 ohne Restwert teilbaren Minutenzahl) auszuführen. (Sprich: :00, :10, :20, :30, :40, :50 Uhr)

Mögliche Werte: 0-59 sowie *

Die erste steht für  Stunden. Mögliche Werte: 0-23 sowie *

Die erste steht für Tag eines Monats. Mögliche Werte: 1-31 sowie *

Die erste steht für das Monat. Mögliche Werte: 1-12 sowie *

Die erste steht für Wochentag. Mögliche Werte: 0-6  sowie * wobei 0 Sonntag, 6 Samstag repräsentiert.

Damit die Umwandlung korrekt durchgeführt werden kann, ist es notwendig
mindestens folgende Attribute im Kunden Mapping eingetragen zu haben:

 - UserCity
 - UserStreet *optional
 - UserCountry

Sollten diese Attribute nicht Ihren entsprechen, können diese über die Sysconfig angepasst werden.
Hinweis:
Die Anfragen an der Google Geocoding API sind auf ca 2000 Anfragen pro Tag limitiert.

Das Umwandeln kann über die Console manuell ausgeführt werden:

    shell> bin/otrs.Console.pl Znuny::CustomerMapBuild
    NOTICE: Done (wrote 209 records).
    shell>


## Sysconfig

 - Znuny4OTRSCustomerMapOnlyOpenTickets
 - Znuny4OTRSCustomerMapCustomerDataAttributes
 - Znuny4OTRSCustomerMapRequiredCustomerDataAttributes
