resource "azurerm_storage_account" "this" {
  name                = "st${var.name_prefix}${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = var.replication_type

  # Drei Wege werden bewusst geschlossen: veraltete Verschluesselung,
  # unverschluesselter Transport, anonymer Einzelzugriff auf Blobs.
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = azurerm_storage_account.this.id
  index_document     = "index.html"
  error_404_document = "404.html"
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
    "ico"  = "image/x-icon"
  }
}

# fileset nimmt jede Datei im Verzeichnis auf. Neue Dateien brauchen
# keinen eigenen Ressourcenblock mehr.
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
