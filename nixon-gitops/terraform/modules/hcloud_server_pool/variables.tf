variable "name" {
  type    = string
  default = null
}

variable "ipv4_enabled" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = null
}

variable "ipv6_enabled" {
  type    = bool
  default = false
}

variable "location" {
  type = string
}

variable "node_type" {
  type = string
}

variable "image" {
  type = string
}

variable "server_count" {
  type = number
}

variable "ssh_key_id" {
  
}

variable "firewall_id" {
  default = null

}

variable "subnet_id" {

}

variable "user_data" {
  type        = string
  default     = null
}