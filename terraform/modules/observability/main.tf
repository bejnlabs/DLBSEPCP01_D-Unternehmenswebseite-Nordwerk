# Zentraler Arbeitsbereich fuer Protokolle und Messwerte. Ohne ihn waeren
# Zugriffe auf die Website nur fluechtig sichtbar.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = var.retention_days

  tags = var.tags
}

# Der Blob-Dienst ist ein Unterdienst des Speicherkontos. Diagnosen
# haengen an ihm, nicht am Konto selbst.
locals {
  blob_service_id = "${var.storage_account_id}/blobServices/default"
}

resource "azurerm_monitor_diagnostic_setting" "blob" {
  name                       = "diag-blob"
  target_resource_id         = local.blob_service_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_metric {
    category = "Transaction"
  }
}

# Warnung, wenn die Fehlerquote steigt. Ein sprunghafter Anstieg von
# Serverfehlern deutet auf ein Problem in der Auslieferung hin.
resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  short_name          = "betrieb"

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "server_errors" {
  name                = "alert-serverfehler"
  resource_group_name = var.resource_group_name
  scopes              = [local.blob_service_id]

  description = "Meldet einen Anstieg serverseitiger Fehler bei der Auslieferung."
  severity    = 2
  frequency   = "PT5M"
  window_size = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/blobServices"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10

    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["ServerOtherError", "ServerTimeoutError"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }

  tags = var.tags
}
