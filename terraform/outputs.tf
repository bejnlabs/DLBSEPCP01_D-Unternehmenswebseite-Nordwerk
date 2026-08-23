output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "storage_account_name" {
  value = module.static_site.storage_account_name
}

output "origin_url" {
  description = "Direkter Endpunkt des Speicherkontos, nur zur Kontrolle"
  value       = module.static_site.primary_web_endpoint
}

output "function_url" {
  description = "Endpunkt der Zaehlerfunktion"
  value       = var.deploy_backend ? "https://${module.backend_api[0].default_hostname}/api/counter" : "nicht bereitgestellt"
}

output "public_url" {
  description = "Oeffentliche Adresse ueber die Edge-Schicht"
  value       = var.deploy_edge ? module.edge[0].endpoint_url : "nicht bereitgestellt"
}
