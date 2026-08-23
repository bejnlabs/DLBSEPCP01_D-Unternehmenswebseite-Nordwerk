# Installationsanleitung

Reproduziert die vollständige Umgebung aus dem Quellcode.

## Voraussetzungen

- Terraform ab 1.5
- Azure CLI ab 2.60
- Ein Azure-Abonnement mit Berechtigung zum Anlegen von Ressourcen
  und Rollenzuweisungen

## Schritte

### 1 Anmelden

```powershell
az login
az account show
```

Die Ausgabe enthält unter `id` die Abonnementkennung.

### 2 Abonnementkennung setzen

```powershell
$env:ARM_SUBSCRIPTION_ID = "<Abonnementkennung>"
```

Nur für die laufende Sitzung. Dauerhaft:

```powershell
[Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "<Kennung>", "User")
```

Die Kennung wird bewusst nicht im Projektverzeichnis abgelegt.

### 3 Werte anpassen

Im Verzeichnis `terraform` eine Datei `terraform.tfvars` anlegen:

```hcl
project_name = "cloudportfolio"
environment  = "dev"
course_id    = "DEIN-KURSKUERZEL"
location     = "germanywestcentral"

deploy_backend = true
deploy_edge    = false
```

`terraform.tfvars` ist von der Versionsverwaltung ausgeschlossen.

### 4 Bereitstellen

```powershell
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

### 5 Prüfen

```powershell
terraform output
```

- `origin_url` öffnet die Seite direkt aus dem Speicherkonto
- `function_url` liefert den Zählerstand als JSON
- `public_url` steht erst zur Verfügung, wenn `deploy_edge = true`

### 6 Edge-Schicht zuschalten

Azure Front Door verursacht eine Grundgebühr von rund 35 US-Dollar
je Monat, unabhängig vom Verkehr. Daher standardmäßig abgeschaltet.

```powershell
terraform apply -var="deploy_edge=true"
```

Nach dem Anlegen dauert es einige Minuten, bis die Konfiguration im
Edge-Netz verteilt ist. Ein Fehler beim ersten Aufruf ist normal.

### 7 Abbauen

```powershell
terraform destroy
```

Entfernt die gesamte Ressourcengruppe. Nach dem Nachweis zwingend
ausführen, sonst laufen die Kosten weiter.

## Bekannte Stolpersteine

| Meldung | Ursache | Abhilfe |
|---|---|---|
| `RequestDisallowedByAzure` | Region durch Abonnementrichtlinie gesperrt | andere Region in `terraform.tfvars` setzen |
| `No subscription found` | Umgebungsvariable nicht gesetzt | Schritt 2 wiederholen |
| `AuthorizationFailed` bei der Rollenzuweisung | fehlende Berechtigung im Abonnement | Rolle "User Access Administrator" oder "Owner" erforderlich |
| Zähler meldet 503 | Rollenzuweisung noch nicht wirksam | ein bis zwei Minuten warten |
| Funktion antwortet mit 404 | Zip-Bereitstellung noch nicht abgeschlossen | einige Minuten warten, dann erneut aufrufen |
