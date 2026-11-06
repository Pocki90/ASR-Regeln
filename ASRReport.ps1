# 1. Speicherort festlegen (Desktop)
$ReportPath = "$home\Desktop\ASR_Dashboard.html"

# 2. Bekannte ASR-Regeln nach GUID in lesbare Namen übersetzen
$ASRRuleMap = @{
    'D4F940AB-401B-4EFC-AADC-AD5F3C50688A' = 'Office: Kindprozesse verhindern'
    '9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2' = 'Credential-Dumping auf LSASS verhindern'
    '5BEB7EFE-FD9A-4556-801D-275E5FFC04CC' = 'Potenziell obfuszierten Script-Code blockieren'
    '01443614-CD74-433A-B99E-2ECDC07BFC25' = 'Ausfuehrung unbekannter EXE-Dateien blockieren'
    'D3E037E1-3EB8-44C8-A917-57927947596D' = 'JavaScript/VBScript startet keine EXE-Dateien'
    '56A863A9-875E-4185-98A7-B882C64B5CE5' = 'Missbrauch von gefaehrlichen signierten Treibern verhindern'
    'E6DB77E5-3DF2-4CF1-B95A-636979351E5B' = 'WMI-Persistenz verhindern'
    '3B576869-A4EC-4529-8536-B80A7769E899' = 'Office-Programme erzeugen keine ausfuehrbaren Inhalte'
    'D1E49AAC-8F56-4280-B9BA-993A6D77406C' = 'PsExec/WMI-Remote-Prozess-Erstellungen verhindern'
    'C1DB55AB-C21A-4637-BB3F-A12568109D35' = 'Erweiterter Schutz gegen Ransomware'
}

function Get-ASRRuleName {
    param(
        [string]$RuleId
    )

    if ([string]::IsNullOrWhiteSpace($RuleId)) {
        return 'Unbekannt'
    }

    if ($ASRRuleMap.ContainsKey($RuleId)) {
        return $ASRRuleMap[$RuleId]
    }

    return "Unbekannt ($RuleId)"
}

function Get-EventDataValue {
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Data,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($Name in $Names) {
        $Value = ($Data | Where-Object { $_.Name -eq $Name } | Select-Object -First 1).'#text'
        if (-not [string]::IsNullOrWhiteSpace($Value)) {
            return $Value
        }
    }

    return ''
}

# 3. Ereignisse der letzten 30 Tage aus der Ereignisanzeige auslesen (ID 1121 = Block, ID 1122 = Audit)
$Events = @(Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Windows Defender/Operational'
    Id = 1121,1122
    StartTime = (Get-Date).AddDays(-30)
} -ErrorAction SilentlyContinue)

# 4. Aktive ASR-Regeln auslesen
$ActiveRuleIds = @()
$ASRPreference = Get-MpPreference -ErrorAction SilentlyContinue
if ($null -ne $ASRPreference -and $null -ne $ASRPreference.AttackSurfaceReductionRules_Ids) {
    $ActiveRuleIds = @($ASRPreference.AttackSurfaceReductionRules_Ids)
}

# 5. Gesamtzählung pro Regel aufbauen
$RuleCounts = @{}
foreach ($CurrentEvent in $Events) {
    $XML = [xml]$CurrentEvent.ToXml()
    $Data = @($XML.Event.EventData.Data)
    $RuleId = Get-EventDataValue -Data $Data -Names @('ID', 'RuleId')

    if (-not [string]::IsNullOrWhiteSpace($RuleId)) {
        if (-not $RuleCounts.ContainsKey($RuleId)) {
            $RuleCounts[$RuleId] = 0
        }
        $RuleCounts[$RuleId]++
    }
}

$RuleOverview = @(foreach ($RuleId in ($ASRRuleMap.Keys + $RuleCounts.Keys | Sort-Object -Unique)) {
    $Count = if ($RuleCounts.ContainsKey($RuleId)) { $RuleCounts[$RuleId] } else { 0 }
    $IsActive = if ($ActiveRuleIds -contains $RuleId) { $true } else { $false }

    $Priority = if ($Count -ge 10) { 'kritisch' }
                elseif ($Count -ge 3) { 'warnend' }
                else { 'normal' }

    [PSCustomObject]@{
        Regel_ID     = $RuleId
        Regel        = Get-ASRRuleName -RuleId $RuleId
        Aktiv        = if ($IsActive) { 'Ja' } else { 'Nein' }
        Ausloesungen = $Count
        Prioritaet   = $Priority
    }
}) | Sort-Object -Property @{Expression = { $_.Aktiv -eq 'Ja' }; Descending = $true }, @{Expression = { $_.Ausloesungen }; Descending = $true }, Regel

# 6. Detaildaten für das Dashboard vorbereiten
$ReportData = foreach ($CurrentEvent in $Events) {
    $XML = [xml]$CurrentEvent.ToXml()
    $Data = @($XML.Event.EventData.Data)
    $RuleId = Get-EventDataValue -Data $Data -Names @('ID', 'RuleId')

    [PSCustomObject]@{
        Zeitpunkt    = $CurrentEvent.TimeCreated.ToString('dd.MM.yyyy HH:mm:ss')
        Typ          = if ($CurrentEvent.Id -eq 1121) { 'BLOCK' } else { 'AUDIT' }
        Regel_ID     = $RuleId
        Regel        = Get-ASRRuleName -RuleId $RuleId
        Prozess      = Get-EventDataValue -Data $Data -Names @('Prozessname', 'Process Name')
        Ziel_Pfad    = Get-EventDataValue -Data $Data -Names @('Pfad', 'Path')
        Befehlszeile = Get-EventDataValue -Data $Data -Names @('Zielbefehlszeile', 'Target Commandline', 'Command line')
    }
}

# 7. Schickes HTML-Design definieren
$HTMLHeader = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f6f8; }
    h2, h3 { color: #2c3e50; }
    h2 { border-bottom: 2px solid #34495e; padding-bottom: 10px; }
    .stats { display: flex; gap: 15px; flex-wrap: wrap; margin: 20px 0; }
    .stat { background: white; border-left: 5px solid #2e86de; box-shadow: 0 2px 5px rgba(0,0,0,0.08); padding: 14px 18px; min-width: 180px; border-radius: 6px; }
    .stat strong { display: block; color: #34495e; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; }
    .stat span { font-size: 26px; font-weight: 700; color: #1f2d3d; }
    table { border-collapse: collapse; width: 100%; background: white; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border-radius: 5px; overflow: hidden; margin-bottom: 25px; }
    th { background-color: #34495e; color: white; text-align: left; padding: 12px; font-size: 14px; }
    td { padding: 10px; border-bottom: 1px solid #eeeeee; font-size: 13px; max-width: 400px; word-wrap: break-word; }
    tr:hover { background-color: #f9f9f9; }
    .BLOCK { color: #c0392b; font-weight: bold; }
    .AUDIT { color: #d35400; font-weight: bold; }
    .ok { color: #2e7d32; font-weight: bold; }
    .no { color: #7f8c8d; font-weight: bold; }
    .kritisch { color: #c0392b; font-weight: bold; }
    .warnend { color: #d35400; font-weight: bold; }
    .normal { color: #2e7d32; font-weight: bold; }
</style>
"@

# 8. HTML-Datei erzeugen
$TotalEvents = $Events.Count
$DistinctRules = $RuleCounts.Count
$ActiveCount = @($ActiveRuleIds).Count

$SummaryRows = foreach ($Rule in $RuleOverview) {
    $CssClass = if ($Rule.Prioritaet -eq 'kritisch') { 'kritisch' }
                elseif ($Rule.Prioritaet -eq 'warnend') { 'warnend' }
                else { 'normal' }

    "<tr><td>$([System.Net.WebUtility]::HtmlEncode($Rule.Regel_ID))</td><td>$([System.Net.WebUtility]::HtmlEncode($Rule.Regel))</td><td>$([System.Net.WebUtility]::HtmlEncode($Rule.Aktiv))</td><td>$($Rule.Ausloesungen)</td><td><span class='$CssClass'>$([System.Net.WebUtility]::HtmlEncode($Rule.Prioritaet))</span></td></tr>"
}

if ($SummaryRows.Count -gt 0) {
    $SummaryHtml = @"
<table>
    <thead>
        <tr>
            <th>Regel-ID</th>
            <th>Regel</th>
            <th>Aktiv</th>
            <th>Ausl&ouml;sungen</th>
            <th>Priorit&auml;t</th>
        </tr>
    </thead>
    <tbody>
        $($SummaryRows -join "`r`n        ")
    </tbody>
</table>
"@
} else {
    $SummaryHtml = '<p>Keine ASR-Regel-Daten vorhanden.</p>'
}

if ($ReportData.Count -gt 0) {
    $DetailHtml = $ReportData | ConvertTo-Html -Fragment
} else {
    $DetailHtml = '<p>Keine ASR-Blockaden in den letzten 30 Tagen gefunden.</p>'
}

$DashboardHtml = @"
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8" />
$HTMLHeader
</head>
<body>
<h2>Lokales Microsoft Defender ASR-Ereignis-Dashboard</h2>
<div class="stats">
    <div class="stat"><strong>Gesamtmeldungen</strong><span>$TotalEvents</span></div>
    <div class="stat"><strong>Aktive ASR-Regeln</strong><span>$ActiveCount</span></div>
    <div class="stat"><strong>Betroffene Regeln</strong><span>$DistinctRules</span></div>
</div>

<h3>ASR-Regel-&Uuml;bersicht</h3>
$SummaryHtml

<h3>Einzeldetails</h3>
$DetailHtml
</body>
</html>
"@

$DashboardHtml | Out-File $ReportPath -Encoding utf8

# 9. Dashboard im Standardbrowser öffnen
Invoke-Item $ReportPath