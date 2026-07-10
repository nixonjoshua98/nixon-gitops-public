variable "hcloud_networks" {
  type = list(object({
    name     = string
    ip_range = string
    subnets = map(object({
      ip_range = string
    }))
  }))
}

variable "hcloud_ssh_keys" {
  type = list(object({
    name            = string
    public_key_path = string
  }))
}

variable "hcloud_server_pools" {
  type = list(object({
    name            = string
    node_type       = string
    count           = number,
    image           = string
    labels          = optional(map(string))
    ipv4_enabled    = optional(bool, true)
    enable_network  = optional(bool, true)
    network_name    = optional(string, "k3s-cluster-network")
    subnet_name     = optional(string, "default-subnet")
    cloud_init_file = optional(string, "cloud-init.yaml")
  }))
  default = []
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "hcloud_firewall_rules" {
  type = list(object({
    description = string
    protocol    = string
    port        = optional(string)
    internal    = optional(bool, false)
    public      = optional(bool, false)
  }))
  default = []
}