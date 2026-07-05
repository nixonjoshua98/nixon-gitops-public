terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm",
      version = "4.69.0"
    }
  }
}

variable "tenant_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vault_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_key_vault" "this" {
  name                       = var.vault_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  tags                       = var.tags
}

output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}
