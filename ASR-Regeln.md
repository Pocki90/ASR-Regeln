# ASR-Regeln für einen guten Gesamtschutz auf Windows

Die folgenden ASR-Regeln bilden keine reine Supply-Chain-Liste, sondern eine solide Grundlage für den allgemeinen Schutz eines Windows-Systems. Ziel ist ein guter Kompromiss aus Sicherheit, Praxisnähe und möglichst wenig Fehlalarmen. Dabei ist die Reihenfolge wichtig: Erst die wichtigsten Regeln in einer sauber überschaubaren Baseline, danach gezielte Zusatzregeln für härteren Schutz.

> Wichtig: Nicht jede ASR-Regel unterstützt den Warn-Modus. Einige Regeln funktionieren nur in Block-Modus. Die LSASS-Regel ist hier ein gutes Beispiel.

---

##### Schritt 1: PowerShell als Administrator öffnen

1. Drücken Sie die Windows-Taste und tippen Sie PowerShell ein.
2. Machen Sie einen Rechtsklick auf Windows PowerShell und wählen Sie Als Administrator ausführen.

---

##### Schritt 2: Empfohlene ASR-Baseline für den allgemeinen Systemschutz

Kopieren Sie die folgenden Befehle nacheinander in die PowerShell und drücken Sie jeweils Enter.

###### 1. Office-Anwendungen sollen keine Kindprozesse mehr starten

Diese Regel verhindert, dass Word, Excel, PowerPoint und ähnliche Programme im Hintergrund Schadcode ausführen, z. B. PowerShell, CMD, Script-Hosts oder andere Payloads. Das ist ein sehr typischer Einstiegspunkt für Malware und Payload-Loader.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Warn
```

###### 2. Credential-Dumping auf LSASS verhindern

Diese Regel blockiert Zugriffe auf den LSASS-Sicherheitsdienst, der häufig für das Auslesen von Passwörtern oder NTLM-Hashes verwendet wird. Das ist ein zentraler Schutz gegen Credential-Stealing und Malware-Toolkit-Angriffe.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2 -AttackSurfaceReductionRules_Actions Warn
```

###### 3. Potenziell obfuskierten Script-Code blockieren

Diese Regel erkennt verdächtige, verschleierte oder stark verschlüsselte Scripts, die typischerweise in Loader-, Droppers oder Malware-Payloads eingesetzt werden. Sie schützt vor einer verbreiteten Tarntechnik, die bei Angriffen häufig genutzt wird.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Warn
```

###### 4. Ausführung unbekannter oder nicht vertrauenswürdiger EXE-Dateien blockieren

Diese Regel verhindert die Ausführung unbekannter oder schwach vertrauenswürdiger EXE-Dateien aus unsicheren Orten wie Temp-Ordnern, Downloads oder Profilverzeichnissen. Das ist ein sehr wirksamer Schutz vor unsicheren Payloads und gebräuchlichen Droppers.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-CD74-433A-B99E-2ECDC07BFC25 -AttackSurfaceReductionRules_Actions Warn
```

###### 5. JavaScript/VBScript soll keine heruntergeladenen EXE-Dateien starten

Diese Regel blockiert das Starten von ausführbaren Dateien durch JavaScript oder VBScript, die aus dem Internet oder einem verdächtigen Download stammen. Das ist ein sehr typischer Weg, um Malware aus einem Browser oder Script-Downloader auszuführen.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids D3E037E1-3EB8-44C8-A917-57927947596D -AttackSurfaceReductionRules_Actions Warn
```

---

##### Warum diese Regeln für den allgemeinen Schutz sinnvoll sind

Diese Regeln decken die häufigsten Ausführungspfade von Malware und Angriffen ab:

- Office-Programme als Einstiegspunkt
- Script- und Downloader-Techniken
- Obfuskation und verschleierte Payload-Ausführung
- Ausführung unbekannter Dateien
- Credential-Dumping auf LSASS

Das ist eine starke Grundlage für den allgemeinen Systemschutz, ohne sofort zu viele Regeln mit hohem Fehlalarm-Risiko zu aktivieren.

---

##### Schritt 3: Die Standard-Protection-Regeln ergänzen

Neben der Baseline gibt es drei Microsoft-Standard-Protection-Regeln, die für den allgemeinen Systemschutz besonders wichtig sind und sinnvoll mit aktiviert werden sollten.

###### 6. Missbrauch von gefährlichen signierten Treibern verhindern

Diese Regel schützt vor der Nutzung bekannter, aber dennoch exploitable Treiber. Solche Treiber können als Angriffswert genutzt werden, um Schutzmechanismen zu umgehen oder die Kernel-Schicht zu kompromittieren.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 56A863A9-875E-4185-98A7-B882C64B5CE5 -AttackSurfaceReductionRules_Actions Warn
```

###### 7. WMI-Persistenz verhindern

Diese Regel blockiert die Nutzung von WMI-Event-Subscriptions zur Persistenz auf dem System. Angreifer verwenden WMI oft, um bösartige Aufgaben oder Hintertüren im Hintergrund zu verstecken und zu starten.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids E6DB77E5-3DF2-4CF1-B95A-636979351E5B -AttackSurfaceReductionRules_Actions Warn
```

###### 8. Office-Programme dürfen keine ausführbaren Inhalte mehr erzeugen

Diese Regel verhindert, dass Office-Dateien dauerhaft bösartige oder persistente Dateien auf der Festplatte erzeugen. Das ist ein typischer Weg, wie Malware nach einem kompromittierten Dokument oder Makro aus dem Office-Kontext weiterlaufen kann.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Warn
```

---

##### Schritt 4: Zusätzliche harte Regeln für anspruchsvollere Umgebungen

Diese Regeln sind sinnvoll, aber in der Praxis meist lauter. Sie eignen sich gut für stärker abgesicherte Umgebungen oder als zweite Stufe nach der Baseline.

###### 9. PSExec- und WMI-Remote-Process-Erstellungen verhindern

Diese Regel blockiert das Starten von Prozessen über PsExec oder WMI-Remoteaufrufe. Solche Mechanismen werden häufig für Lateral Movement, Remote Execution und Angriffe im Netzwerk verwendet.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids D1E49AAC-8F56-4280-B9BA-993A6D77406C -AttackSurfaceReductionRules_Actions Warn
```

###### 10. Erweiterter Schutz gegen Ransomware aktivieren

Diese Regel versucht, ransomware-typisches Verhalten zu erkennen, auch wenn ein Datei-Hash oder eine Reputation noch nicht eindeutig ist. Sie ist gut für den Schutz vor Verschlüsselungsangriffen, kann aber je nach Umgebung etwas mehr Ausnahmen nötig machen.

```powershell
Add-MpPreference -AttackSurfaceReductionRules_Ids C1DB55AB-C21A-4637-BB3F-A12568109D35 -AttackSurfaceReductionRules_Actions Warn
```

---

##### Schritt 5: Den Status überprüfen

Prüfen, ob die Regeln im System hinterlegt sind:

```powershell
Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids -ErrorAction SilentlyContinue
```

Prüfen, ob die Regeln im Warn- oder Block-Modus aktiv sind:

```powershell
Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Actions -ErrorAction SilentlyContinue
```

Für Warn-Regeln gilt normalerweise: Der Wert 6 zeigt den Warn-Modus an. Für Block-Regeln ist die genaue Interpretation je nach Konfiguration etwas unterschiedlich, aber sie sind aktiv, sobald die Regel im System aufgelistet wird.

---

##### Wichtige Hinweise zur Nutzung

- Die LSASS-Regel unterstützt keinen Warn-Modus und sollte daher in Block-Modus gesetzt werden.
- Die Regeln 3, 4, 7, 9 und 10 können in einigen Umgebungen mehr Fehlalarme erzeugen; deshalb zunächst in Warn-Modus testen.
- Wenn eine Anwendung fälschlich blockiert wird, kann sie über die Funktion „Trotzdem erlauben“ oder über eine gezielte ASR-Ausnahme wieder freigegeben werden.
- Die Regeln funktionieren besonders gut, wenn Microsoft Defender Antivirus und Cloud Protection korrekt aktiviert sind.

---

#### Wie verhält sich Windows ab jetzt?

Wenn eine Anwendung eine dieser ASR-Regeln triggert, passiert in der Regel Folgendes:

1. Das verdächtige Verhalten wird sofort erkannt.
2. Windows zeigt eine Benachrichtigung an.
3. Es erscheint ein Dialog mit „Trotzdem erlauben“ oder „Ausnahme hinzufügen“.
4. Wenn Sie der Software vertrauen, können Sie eine Ausnahme ergänzen.
5. Wenn nicht, bleibt die Ausführung blockiert.

---

#### Empfehlung für die Praxis

Für einen guten allgemeinen Schutz auf einem normalen Windows-System ist die beste Reihenfolge:

1. Baseline aktivieren
2. Standard-Protection ergänzen
3. Danach die lautereren Regeln gezielt testen und bei Bedarf aufnehmen

Das ist meist deutlich stabiler als sofort alle möglichen Regeln zu aktivieren.

