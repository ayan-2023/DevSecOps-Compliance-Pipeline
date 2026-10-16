resource "azurerm_resource_group" "compliance_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "compliance_sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.compliance_rg.name
  location                 = azurerm_resource_group.compliance_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}
