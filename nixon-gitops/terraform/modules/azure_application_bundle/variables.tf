variable "display_name" {
  type = string
}

variable "client_secrets" {
  type = list(string)
  default = []
}

variable "federated_credentials" {
  type = list(object({
    organisation = string
    repository   = string
    branches     = list(string)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
