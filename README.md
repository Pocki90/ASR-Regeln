# Windows Defender ASR-Regeln und Reporting

Dieses Repository enthält eine empfohlene Baseline für Microsoft Defender Attack Surface Reduction (ASR) unter Windows sowie ein PowerShell-Skript, das ASR-Ereignisse aus dem Ereignisprotokoll ausliest und als HTML-Dashboard visualisiert.

## Inhalt

- `ASR-Regeln.md` – Empfehlung für eine sinnvolle ASR-Baseline mit Erläuterungen und PowerShell-Befehlen
- `ASRReport.ps1` – sammelt ASR-Ereignisse der letzten 30 Tage und erzeugt ein lokales HTML-Dashboard

## Ziel

Das Repository hilft dabei:

- ASR-Regeln sinnvoll und praxisnah zu aktivieren
- die wichtigsten Defender-ASR-Regeln zu verstehen
- ASR-Aktivitäten im Betrieb zu überwachen
- Blockaden und Audit-Ereignisse übersichtlich auszuwerten

## Voraussetzungen

- Windows 10 oder Windows 11
- Microsoft Defender Antivirus aktiviert
- PowerShell mit lokalen Administratorrechten
- Zugriff auf das Ereignisprotokoll `Microsoft-Windows-Windows Defender/Operational`

## ASR-Baseline nutzen

1. PowerShell als Administrator öffnen.
2. Die empfohlenen Befehle aus `ASR-Regeln.md` ausführen.
3. Für einen sicheren Start werden zunächst die wichtigsten Regeln im Warn-Modus aktiviert.
4. Danach die Regeln gezielt prüfen und bei Bedarf anpassen.

## Dashboard generieren

So wird das HTML-Dashboard erstellt:

```powershell
.\ASRReport.ps1
```

Sollte das Skript nicht wie erwartet starten, prüfen Sie bitte ob die Script-Ausführungsrichtlinie dies zulässt. Sie können eine einmalige Scriptausführung mit folgendem Befehl erlauben:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Das Skript erstellt eine Datei am Desktop:

```powershell
$HOME\Desktop\ASR_Dashboard.html
```

## Was das Skript macht

- liest ASR-Ereignisse mit den IDs `1121` und `1122` aus den letzten 30 Tagen
- prüft, welche ASR-Regeln aktuell aktiviert sind
- zählt Auslösungen pro Regel
- bewertet die Priorität je nach Anzahl der Ereignisse
- erstellt ein übersichtliches HTML-Dashboard mit:
  - Gesamtzahl der Meldungen
  - Anzahl aktiver ASR-Regeln
  - betroffene Regeln
  - Regelübersicht
  - Detailansicht der Einzelergebnisse

## Beispiel für die Regelzuordnung

Im Script werden bekannte ASR-Regel-GUIDs in lesbare Namen übersetzt, z. B.:

- `D4F940AB-401B-4EFC-AADC-AD5F3C50688A` → Office: Kindprozesse verhindern
- `9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2` → Credential-Dumping auf LSASS verhindern
- `C1DB55AB-C21A-4637-BB3F-A12568109D35` → Erweiterter Schutz gegen Ransomware

## Hinweise

- Einige ASR-Regeln unterstützen keinen Warn-Modus und müssen in Block-Modus gesetzt werden.
- Die Ergebnisse hängen von den aktivierten Regeln und dem tatsächlichen Systemverhalten ab.
- Für produktive Umgebungen sollte die Regelauswertung mit den eigenen Sicherheitsanforderungen abgestimmt werden.

## Lizenz

Dieses Repository dient als interne Sicherheits- und Betriebsdokumentation. Die Nutzung ist frei, sofern die Inhalte in eigener Verantwortung und entsprechend den geltenden Richtlinien verwendet werden.

## Empfehlung

Für den normalen Windows-Einsatz ist die beste Vorgehensweise:

1. Baseline aktivieren
2. Standard-Protection ergänzen
3. lauterere Regeln gezielt testen
4. Dashboard regelmäßig prüfen

Damit bleibt der Schutz wirksam, ohne sofort zu viele Regeln mit hohem Fehlalarmrisiko zu aktivieren.
