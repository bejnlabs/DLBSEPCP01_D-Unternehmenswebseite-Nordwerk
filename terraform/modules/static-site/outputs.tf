output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "primary_web_host" {
  description = "Hostname des Website-Endpunkts, dient Front Door als Ursprung"
  value       = azurerm_storage_account.this.primary_web_host
}

output "primary_web_endpoint" {
  value = azurerm_storage_account.this.primary_web_endpoint
}
