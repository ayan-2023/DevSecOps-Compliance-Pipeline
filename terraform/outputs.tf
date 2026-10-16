output "resource_group_id" {
  description = "The ID of the Azure Resource Group"
  value       = azurerm_resource_group.compliance_rg.id
}

output "storage_account_id" {
  description = "The ID of the secure Storage Account"
  value       = azurerm_storage_account.compliance_sa.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary Blob Service endpoint URL"
  value       = azurerm_storage_account.compliance_sa.primary_blob_endpoint
}
