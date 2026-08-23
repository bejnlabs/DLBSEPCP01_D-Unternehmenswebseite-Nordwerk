output "endpoint_host_name" {
  value = azurerm_cdn_frontdoor_endpoint.web.host_name
}

output "endpoint_url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.web.host_name}"
}
