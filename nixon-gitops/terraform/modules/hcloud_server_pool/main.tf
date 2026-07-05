locals {
  full_name     = "${var.name}-${var.location}-${var.node_type}"
  server_names  = toset([ for i in range(var.server_count) : "${local.full_name}-${format("%03d", i)}" ])
}

resource "hcloud_placement_group" "this" {
  name = var.name
  type = "spread"
}

resource "hcloud_server" "servers" {
  for_each                    = local.server_names
  name                        = each.value
  image                       = var.image
  server_type                 = var.node_type
  location                    = var.location
  ssh_keys                    = [var.ssh_key_id]
  firewall_ids                = var.firewall_id == null ? null : [var.firewall_id]
  placement_group_id          = hcloud_placement_group.this.id
  keep_disk                   = true
  user_data                   = var.user_data
  labels                      = var.labels != null ? var.labels : {}
  
  public_net {
    ipv4_enabled = var.ipv4_enabled
    ipv6_enabled = var.ipv6_enabled
  }

  lifecycle {
    ignore_changes = [ name, ssh_keys, user_data ]
  }
}

resource "hcloud_server_network" "server_networks" {
  for_each  = var.subnet_id == null ? [] : local.server_names
  server_id = hcloud_server.servers[each.value].id
  subnet_id = var.subnet_id
}