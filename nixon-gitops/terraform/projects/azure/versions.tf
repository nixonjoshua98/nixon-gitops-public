terraform {
  required_version = ">= 1.14.9"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.8.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm",
      version = "4.69.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = var.azure_subscription_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}
