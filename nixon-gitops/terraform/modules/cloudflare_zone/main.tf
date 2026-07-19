
resource "cloudflare_dns_record" "records" {
  for_each = { for x in var.records : "${x.type}-${x.name}-${x.content}" => x }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  proxied = each.value.proxied
  ttl     = 1
  comment = "Managed by Terraform"
}

resource "cloudflare_ruleset" "dynamic_redirects" {
  count   = length(var.redirects) > 0 ? 1 : 0
  zone_id = var.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [
    for redirect in var.redirects : {
      action      = "redirect"
      expression  = "(http.request.full_uri wildcard r\"${redirect.request_url}\")"
      description = redirect.description
      action_parameters = {
        from_value = {
          status_code           = redirect.status_code
          preserve_query_string = redirect.preserve_query_string

          target_url = {
            expression = "wildcard_replace(http.request.full_uri, r\"${redirect.request_url}\", r\"${redirect.target_url}\")"
          }
        }
      }
    }
  ]
}

resource "cloudflare_ruleset" "custom_waf_rules" {
  count   = length(var.waf_rules) > 0 ? 1 : 0
  zone_id = var.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    for rule in var.waf_rules : 
      {
        action            = "block"
        expression        = rule.expression,
        description       = rule.description
      }
  ]
}
