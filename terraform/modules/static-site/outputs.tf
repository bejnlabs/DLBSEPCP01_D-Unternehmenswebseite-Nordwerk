output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "primary_web_endpoint" {
  value = azurerm_storage_account.this.primary_web_endpoint
}

output "primary_web_host" {
  value = azurerm_storage_account.this.primary_web_host
}

output "replication_type" {
  value = azurerm_storage_account.this.account_replication_type
}
