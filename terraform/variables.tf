variable "resource_group_name" {
  type        = string
  description = "The name of the target Azure resource group"
  default     = "rg-devsecops-compliance"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, preprod, prod)"
  default     = "prod"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account for compliance artifacts"
  default     = "stdevsecopscomp001"
}

variable "tags" {
  type        = map(string)
  description = "Standard resource tags for governance and cost tracking"
  default = {
    Project     = "DevSecOps-Compliance-Pipeline"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}
