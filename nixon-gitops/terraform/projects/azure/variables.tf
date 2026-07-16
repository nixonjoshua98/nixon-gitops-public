
variable "azure_resource_groups" {
  type = list(object({
    name = string
  }))
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_key_vaults" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "azure_container_registries" {
  type = list(object({
    name                  = string
    resource_group_name   = string
    rbac_role_assignments = optional(map(list(string)), {})
  }))
}

variable "azure_storage_accounts" {
  type = list(object({
    name                = string
    resource_group_name = string
  }))
}

variable "azure_common_labels" {
  type    = map(string)
  default = {}
}

variable "azure_applications" {
  type = list(object({
    name           = string
    client_secrets = optional(list(string), [])
    federated_credentials = optional(list(object({
      organisation = optional(string)
      repository   = optional(string)
      branches     = optional(list(string))
    })), [])
  }))
  default = []
}

variable "azure_groups" {
  type = map(object({
    member_emails = list(string)
    display_name  = optional(string)
    mail_nickname = optional(string)
  }))
  default = {}
}
