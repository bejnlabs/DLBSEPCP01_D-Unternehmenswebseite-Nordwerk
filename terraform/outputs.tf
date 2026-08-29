output "resource_group_name" {
  description = "Name der Ressourcengruppe"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name des Speicherkontos"
  value       = module.static_site.storage_account_name
}

output "website_url" {
  description = "Oeffentliche Adresse der Website"
  value       = module.static_site.primary_web_endpoint
}

output "replication_type" {
  description = "Tatsaechlich gesetzte Replikationsart"
  value       = module.static_site.replication_type
}

output "log_analytics_workspace" {
  description = "Name des Arbeitsbereichs fuer die Betriebsueberwachung"
  value       = var.deploy_observability ? module.observability[0].workspace_name : "nicht bereitgestellt"
}
