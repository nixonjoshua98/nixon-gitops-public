variable "zone_id" {
  type = string
}

variable "records" {
  type = list(object({
    type    = string
    name    = string
    content = string
    proxied = bool
  }))
  default = []
}

variable "redirects" {
  type = list(object({
    description           = optional(string, "")
    request_url           = string
    target_url            = string
    status_code           = number
    preserve_query_string = bool
  }))
  default = []
}

variable "waf_rules" {
  type = list(object({
    expression        = string
    description       = string
  }))
  default = []
}
