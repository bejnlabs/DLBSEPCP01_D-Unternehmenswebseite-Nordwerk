output "default_hostname" {
  description = "Hostname der Function App, dient Front Door als zweiter Ursprung"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "function_app_name" {
  value = azurerm_linux_function_app.this.name
}

output "principal_id" {
  description = "Objektkennung der verwalteten Identitaet"
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}
