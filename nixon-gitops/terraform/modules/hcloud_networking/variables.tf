
variable "network_name" {
  type = string
}

variable "network_ip_range" {
  type = string
}

variable "network_zone" {
  type = string
}

variable "subnets" {
  type = map(object({
    ip_range = string
  }))
}