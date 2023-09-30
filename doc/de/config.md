# Konfiguration

Um Kundenstandorte anzuzeigen ist es notwendig einen Google-Maps-Browser-API-Key zu besitzen.
Dieser Key ist dann in der SysConfig-Option `Znuny::CustomerMap::GoogleAPIKey` einzutragen.

## Koordinaten der Kundenstandorte ermitteln

Für die regelmäßige Umwandlung der Adressdaten ist es notwendig das der Znuny-Daemon läuft. Er führt die Aktualisierung täglich um 3:45 Uhr aus.

Über die Änderung der SysConfig-Option `Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap` ist die Zeit der Ausführung änderbar.

Damit die Umwandlung korrekt durchgeführt werden kann, ist es notwendig
mindestens folgende Attribute im Customer-Mapping einzutragen:

 - UserCity
 - UserStreet (optional)
 - UserCountry

Sollten diese Attribute nicht Ihren entsprechen, können diese über die SysConfig angepasst werden.

Hinweis:
Die Anfragen an die Google-Geocoding-API unterliegen Limitierungen. Details dazu entnehmen Sie bitte der Dokumentation der Google Maps API.

Die konfigurierten Felder werden als kombinierter Adressstring zur Standortabfrage an Google übertragen.

Die Umwandlung kann über die Konsole als Znuny-Benutzer auch manuell ausgeführt werden:

```
    shell> bin/znuny.Console.pl Znuny::CustomerMap::Build
    NOTICE: Done (wrote 209 records).
    shell>
```

## Einstellungen System Configuration

### Znuny::CustomerMap::GoogleAPIKey

In dieser Einstellung ist der API-Key einzutragen den Sie über den Link https://developers.google.com/maps/documentation/javascript/get-api-key erhalten. Ohne diese API-Key ist eine Nutzung des Addons nicht möglich.

### Znuny::CustomerMap::CustomerDataAttributes

Hiermit wird festgelegt aus welchen Attributen Ihrer Kundenbenutzer-Datenbenk (CustomerUser) die für die Ermittlung er Koordinaten notwendigen Informationen bezogen werden. Tragen Sie dazu bitte als Wert den passenden Namen aus der ersten Spalte des Mappings ein. Die Namen der Schlüssel belassen Sie bitte unverändert.

### Znuny::CustomerMap::RequiredCustomerDataAttributes

Diese Attribute werden mindestens benötigt um um die Koordinaten zu einer Adresse zu ermitteln.

### Znuny::CustomerMap::CustomerSelection

Diese Einstellung legt fest ob nur die Standorte der Kunden mit offenen Tickets angezeigt werden sollen, oder die von den Kunden zu denen er geschlossene Tickets gibt.


### Daemon::SchedulerCronTaskManager::Task###UpdateCustomerMap

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

## Hinweise

Eine Darstellung von Kunden, die noch kein Ticket hatten ist nicht möglich. Die Funktion CustomerUserList, die sämtliche Kunden aus der Datenbank holt ([siehe Git Commit](https://github.com/znuny/Znuny/commit/3a59683b3cd8cf5c1008150706d23677116736fc)), wurde aus Znuny entfernt.
