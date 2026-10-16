terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
  backend "azurerm" {
    # Backend values supplied dynamically via Azure DevOps pipeline variable group
    # resource_group_name  = var.backendAzureRmResourceGroupName
    # storage_account_name = var.backendAzureRmStorageAccountName
    # container_name       = var.backendAzureRmContainerName
    # key                  = var.backendAzureRmKey
  }
}

provider "azurerm" {
  features {}
}
