

/*
    The firewall is attached to all created servers to ensure that the necessary ports are open for the cluster to function properly.
    NB, we use a firewall attachment as we require the servers being created before we can attach the firewall
*/

resource "hcloud_firewall" "this" {
  name = "k3s-cluster-firewall"

  dynamic "rule" {
    for_each = var.hcloud_firewall_rules
    content {
      description = rule.value.description
      direction   = "in"
      protocol    = rule.value.protocol
      port        = rule.value.port
      source_ips  = (
        rule.value.public ? 
          concat(local.machine_ips, local.created_server_ips, local.cloudflare_ips) :
          concat(local.machine_ips, local.created_server_ips)
      )
    }
  }
}

resource "hcloud_firewall_attachment" "fw_servers" {
  firewall_id     = hcloud_firewall.this.id
  label_selectors = [for s in local.server_pools : "server-pool-name=${s.name}"]
}