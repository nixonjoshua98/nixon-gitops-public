
// -- Versions -- //

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.69.0"
    }
  }
}

// -- Variables -- //

variable "resource_group_name" {
  type = string
}

variable "registry_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "purge_older_than_days" {
  type    = number
  default = 30
}

variable "purge_retain_count" {
  type    = number
  default = 5
}

// -- Registry -- //

resource "azurerm_container_registry" "registry" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  tags                = var.tags
}

// -- Tasks -- //

resource "azurerm_container_registry_task" "purge_task" {
  name                  = "purge-task"
  container_registry_id = azurerm_container_registry.registry.id
  tags                  = var.tags

  platform {
    os = "Linux"
  }

  encoded_step {
    task_content = <<-EOT
      version: v1.1.0
      steps:
        - cmd: acr purge --filter '.*:.*' --ago ${var.purge_older_than_days}d --keep ${var.purge_retain_count}
          timeout: 60
    EOT
  }

  timer_trigger {
    name     = "purge-timer"
    schedule = "0 0 * * 0"
    enabled  = true
  }
}

// -- Outputs -- //

output "id" {
  value = azurerm_container_registry.registry.id
}

output "login_server" {
  value = azurerm_container_registry.registry.login_server
}

output "name" {
  value = azurerm_container_registry.registry.name
}
