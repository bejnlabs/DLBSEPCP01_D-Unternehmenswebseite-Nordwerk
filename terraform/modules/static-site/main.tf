resource "azurerm_storage_account" "this" {
  name                = "st${var.name_prefix}${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = var.replication_type

  # Drei Wege werden bewusst geschlossen: veraltete Verschluesselung,
  # unverschluesselter Transport, anonymer Einzelzugriff auf Blobs.
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Zugriff ueber Verzeichnisidentitaeten statt Kontoschluessel bevorzugen.
  default_to_oauth_authentication = true

  blob_properties {
    # Versionierung: eine fehlerhaft ueberschriebene Seite bleibt
    # wiederherstellbar, ohne dass ein Backup noetig waere.
    versioning_enabled = var.versioning_enabled

    delete_retention_policy {
      days = var.retention_days
    }

    container_delete_retention_policy {
      days = var.retention_days
    }
  }

  tags = var.tags
}

resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = azurerm_storage_account.this.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# Alte Versionen wachsen sonst unbegrenzt mit. Die Regel begrenzt den
# Speicherbedarf und damit die Kosten, ohne die Wiederherstellbarkeit
# innerhalb des Zeitfensters einzuschraenken.
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "alte-versionen-entfernen"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = var.old_version_expiry_days
      }
    }
  }
}

locals {
  content_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "svg"  = "image/svg+xml"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "webp" = "image/webp"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
  }
}

# fileset nimmt jede Datei im Verzeichnis auf. Neue Seiten brauchen
# keinen eigenen Ressourcenblock.
resource "azurerm_storage_blob" "content" {
  for_each = fileset(var.website_source_path, "**")

  name                   = each.value
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"

  content_type = lookup(
    local.content_types,
    lower(element(split(".", each.value), length(split(".", each.value)) - 1)),
    "application/octet-stream"
  )

  source = "${var.website_source_path}/${each.value}"

  # Ohne Pruefsumme vergleicht Terraform nur Dateipfade. Eine geaenderte
  # Datei wuerde als unveraendert gelten und nie hochgeladen.
  content_md5 = filemd5("${var.website_source_path}/${each.value}")

  depends_on = [azurerm_storage_account_static_website.this]
}
