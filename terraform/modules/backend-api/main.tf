# Eigenes Speicherkonto fuer die Funktionslaufzeit und den Zaehlerstand.
# Bewusst getrennt vom Website-Konto: andere Zugriffsmuster, andere Rechte.
resource "azurerm_storage_account" "fn" {
  name                = "stfn${var.name_prefix}${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_table" "counter" {
  name                 = "visitorcounter"
  storage_account_name = azurerm_storage_account.fn.name
}

# Y1 ist das Verbrauchsmodell: keine vorgehaltene Instanz, Abrechnung
# je Ausfuehrung, Skalierung ab null.
resource "azurerm_service_plan" "consumption" {
  name                = "asp-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

data "archive_file" "fn" {
  type        = "zip"
  source_dir  = var.function_source_dir
  output_path = "${path.module}/function.zip"
}

resource "azurerm_linux_function_app" "this" {
  name                = "func-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.consumption.id

  storage_account_name       = azurerm_storage_account.fn.name
  storage_account_access_key = azurerm_storage_account.fn.primary_access_key

  https_only      = true
  zip_deploy_file = data.archive_file.fn.output_path

  # Systemseitig verwaltete Identitaet: die Funktion erhaelt eine eigene
  # Identitaet im Verzeichnis, es entsteht kein Schluessel im Code.
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
    minimum_tls_version = "1.2"

    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    # Abhaengigkeiten werden in Azure gebaut, nicht lokal mitgeliefert.
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    ENABLE_ORYX_BUILD              = "true"

    TABLE_ENDPOINT = azurerm_storage_account.fn.primary_table_endpoint
    TABLE_NAME     = azurerm_storage_table.counter.name
  }

  tags = var.tags
}

# Geringste Rechte: die Rolle gilt nur fuer den Tabellendienst genau
# dieses Kontos, nicht fuer die Ressourcengruppe.
resource "azurerm_role_assignment" "table" {
  scope                = azurerm_storage_account.fn.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}
