resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = "afd-${var.name_prefix}-${var.suffix}"
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = 30
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "web" {
  name                     = "ep-${var.name_prefix}-${var.suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

# ---------- Ursprung 1: statische Website ----------
resource "azurerm_cdn_frontdoor_origin_group" "web" {
  name                     = "og-static"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/index.html"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "web" {
  name                          = "origin-storage"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  enabled                       = true

  host_name          = var.origin_host_name
  origin_host_header = var.origin_host_name
  https_port         = 443
  http_port          = 80
  priority           = 1
  weight             = 1

  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "web" {
  name                          = "route-web"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.web.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.web.id]

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true

  cache {
    compression_enabled           = true
    query_string_caching_behavior = "IgnoreQueryString"
    content_types_to_compress = [
      "text/html", "text/css", "text/javascript",
      "application/javascript", "application/json", "image/svg+xml"
    ]
  }
}

# ---------- Ursprung 2: Zaehlerfunktion ----------
# Ohne diese Route liefe der Zaehler am Edge-Netz vorbei und das
# Architekturbild waere unzutreffend.
resource "azurerm_cdn_frontdoor_origin_group" "api" {
  count                    = var.api_host_name == null ? 0 : 1
  name                     = "og-api"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }
}

resource "azurerm_cdn_frontdoor_origin" "api" {
  count                         = var.api_host_name == null ? 0 : 1
  name                          = "origin-function"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api[0].id
  enabled                       = true

  host_name          = var.api_host_name
  origin_host_header = var.api_host_name
  https_port         = 443
  http_port          = 80
  priority           = 1
  weight             = 1

  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "api" {
  count                         = var.api_host_name == null ? 0 : 1
  name                          = "route-api"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.web.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.api[0].id]

  patterns_to_match      = ["/api/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true

  # Bewusst ohne cache-Block: der Zaehlerstand aendert sich bei jedem
  # Aufruf und darf nicht zwischengespeichert werden.
}
