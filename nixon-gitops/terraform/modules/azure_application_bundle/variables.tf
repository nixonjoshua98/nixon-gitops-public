variable "display_name" {
  type = string
}

variable "client_secrets" {
  type    = list(string)
  default = []
}

variable "federated_credentials" {
  type = list(object({
    subject_identifier = optional(string)
    issuer             = optional(string)
    kubernetes_namespace = optional(object({
      namespace       = string
      issuer          = string
      serviceaccounts = list(string)
    }))
    github = optional(object({
      organisation = string
      repository   = string
      branches     = list(string)
    }))
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}