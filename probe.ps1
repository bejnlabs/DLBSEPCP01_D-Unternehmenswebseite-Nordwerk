# ============================================================
#  Machbarkeitstest fuer das Cloud-Programming-Portfolio
#
#  Prueft, welche Azure-Dienste im vorliegenden Abonnement
#  tatsaechlich angelegt werden koennen. Legt eine eigene
#  Ressourcengruppe an und entfernt sie am Ende vollstaendig.
#
#  Aufruf:  .\probe.ps1
# ============================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$rg = 'rg-machbarkeitstest'
$suffix = -join ((97..122) + (48..57) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$ergebnisse = @()

function Schreibe($text, $farbe = 'Gray') {
    Write-Host $text -ForegroundColor $farbe
}

function Test-Dienst {
    param(
        [string]$Id,
        [string]$Dienst,
        [string]$Region,
        [scriptblock]$Aktion
    )
    Write-Host ("  {0,-4} {1,-42} {2,-22}" -f $Id, $Dienst, $Region) -NoNewline
    $ausgabe = & $Aktion 2>&1 | Out-String
    $erfolg = ($LASTEXITCODE -eq 0)

    if ($erfolg) {
        Write-Host 'OK' -ForegroundColor Green
        $grund = ''
    } else {
        Write-Host 'GESPERRT' -ForegroundColor Red
        # Kurzen Grund aus der Fehlermeldung ziehen
        $grund = ''
        if ($ausgabe -match 'forbidden for Azure Frontdoor')      { $grund = 'Front Door fuer Studierendenabo verboten' }
        elseif ($ausgabe -match 'additional quota')               { $grund = 'Kontingent 0, Erhoehung noetig' }
        elseif ($ausgabe -match 'RequestDisallowedByAzure')       { $grund = 'Region durch Abonnementrichtlinie gesperrt' }
        elseif ($ausgabe -match 'SubscriptionNotAllowed')         { $grund = 'Abonnementtyp nicht zugelassen' }
        elseif ($ausgabe -match 'not available in the location|LocationNotAvailable') { $grund = 'In dieser Region nicht verfuegbar' }
        elseif ($ausgabe -match 'is not registered|NotRegistered'){ $grund = 'Ressourcenanbieter nicht registriert' }
        elseif ($ausgabe -match 'QuotaExceeded')                  { $grund = 'Kontingent ausgeschoepft' }
        else {
            $zeile = ($ausgabe -split "`n" | Where-Object { $_ -match 'ERROR|Code|Message' } | Select-Object -First 1)
            $grund = if ($zeile) { $zeile.Trim().Substring(0, [Math]::Min(70, $zeile.Trim().Length)) } else { 'unbekannt' }
        }
    }

    $script:ergebnisse += [pscustomobject]@{
        Id      = $Id
        Dienst  = $Dienst
        Region  = $Region
        Status  = $(if ($erfolg) { 'OK' } else { 'GESPERRT' })
        Grund   = $grund
    }
}

# ------------------------------------------------------------
Schreibe ''
Schreibe '============================================================' Cyan
Schreibe '  Machbarkeitstest Azure-Dienste' Cyan
Schreibe '============================================================' Cyan
Schreibe ''

$abo = az account show --query name -o tsv 2>$null
if (-not $abo) {
    Schreibe 'Nicht angemeldet. Bitte zuerst: az login' Red
    exit 1
}
Schreibe "Abonnement: $abo"
Schreibe "Testgruppe: $rg"
Schreibe ''

Schreibe 'Ressourcengruppe wird angelegt ...'
az group create -n $rg -l germanywestcentral --tags zweck=machbarkeitstest -o none 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Schreibe 'Ressourcengruppe konnte nicht angelegt werden. Region pruefen.' Red
    exit 1
}
Schreibe ''
Write-Host ("  {0,-4} {1,-42} {2,-22}{3}" -f 'Nr', 'Dienst', 'Region', 'Ergebnis') -ForegroundColor White
Write-Host ('  ' + ('-' * 84)) -ForegroundColor DarkGray

# ---------- Gruppe 1: Verbrauchsmodell in mehreren Regionen ----------
foreach ($r in @('germanywestcentral', 'westeurope', 'northeurope', 'swedencentral')) {
    $i = @('germanywestcentral', 'westeurope', 'northeurope', 'swedencentral').IndexOf($r) + 1
    Test-Dienst "T$i" 'App Service Plan Y1 (Verbrauchsmodell)' $r {
        az appservice plan create -g $rg -n "asp-y1-$r-$suffix" -l $r --is-linux --sku Y1 -o none 2>&1
    }
}

# ---------- Gruppe 2: andere Tarife ----------
Test-Dienst 'T5' 'App Service Plan F1 (kostenlos)' 'germanywestcentral' {
    az appservice plan create -g $rg -n "asp-f1-$suffix" -l germanywestcentral --is-linux --sku F1 -o none 2>&1
}
Test-Dienst 'T6' 'App Service Plan B1 (Basis)' 'germanywestcentral' {
    az appservice plan create -g $rg -n "asp-b1-$suffix" -l germanywestcentral --is-linux --sku B1 -o none 2>&1
}

# ---------- Gruppe 3: Static Web Apps ----------
Test-Dienst 'T7' 'Static Web App (kostenloser Tarif)' 'westeurope' {
    az staticwebapp create -g $rg -n "swa-$suffix" -l westeurope --sku Free -o none 2>&1
}

# ---------- Gruppe 4: Container ----------
Test-Dienst 'T8' 'Container Instance' 'germanywestcentral' {
    az container create -g $rg -n "aci-$suffix" -l germanywestcentral `
        --image mcr.microsoft.com/azuredocs/aci-helloworld `
        --cpu 1 --memory 1 --os-type Linux -o none 2>&1
}

# ---------- Gruppe 5: Netzrand (Edge) ----------
Test-Dienst 'T9' 'Front Door Standard' 'global' {
    az afd profile create -g $rg --profile-name "afd-$suffix" --sku Standard_AzureFrontDoor -o none 2>&1
}

# ---------- Gruppe 6: Persistenz ----------
Test-Dienst 'T10' 'Storage Account ZRS' 'germanywestcentral' {
    az storage account create -g $rg -n "stzrs$suffix" -l germanywestcentral `
        --sku Standard_ZRS --kind StorageV2 -o none 2>&1
}

# ------------------------------------------------------------
Schreibe ''
Schreibe '============================================================' Cyan
Schreibe '  Ergebnis' Cyan
Schreibe '============================================================' Cyan
Schreibe ''

$ergebnisse | Format-Table Id, Dienst, Region, Status, Grund -AutoSize | Out-String -Width 160 | Write-Host

$ok = ($ergebnisse | Where-Object Status -eq 'OK').Count
$nok = ($ergebnisse | Where-Object Status -eq 'GESPERRT').Count
Schreibe "  Verfuegbar: $ok   Gesperrt: $nok" White
Schreibe ''

# Ergebnis als Datei sichern
$datei = Join-Path $PSScriptRoot 'ergebnis.txt'
"Machbarkeitstest $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $datei
"Abonnement: $abo" | Out-File $datei -Append
'' | Out-File $datei -Append
$ergebnisse | Format-Table Id, Dienst, Region, Status, Grund -AutoSize |
    Out-String -Width 160 | Out-File $datei -Append
Schreibe "  Ergebnis gesichert in: $datei" DarkGray
Schreibe ''

# ------------------------------------------------------------
Schreibe 'Testgruppe wird entfernt ...' Yellow
az group delete -n $rg --yes --no-wait -o none 2>&1 | Out-Null
Schreibe 'Loeschung im Hintergrund gestartet. Kontrolle:' DarkGray
Schreibe '  az group list --output table' DarkGray
Schreibe ''
