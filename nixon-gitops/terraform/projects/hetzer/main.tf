locals {
  created_servers = [
    for s in flatten([for _, mod in module.hcloud_server_pools : mod.servers]) : {
      name         = s.name
      ipv4_address = s.ipv4_address
      ipv6_address = s.ipv6_address
      role         = try(s.labels["role"], "")
    }
  ]

  created_server_ips = concat(
    [for s in local.created_servers : s.ipv4_address if s.ipv4_address != null],
    [for s in local.created_servers : s.ipv6_address if s.ipv6_address != null]
  )

  server_pools = {
    for sp in var.hcloud_server_pools : sp.name => {
      name            = sp.name
      node_type       = sp.node_type
      image           = sp.image
      count           = sp.count
      network_name    = sp.enable_network ? sp.network_name : null
      subnet_name     = sp.enable_network ? sp.subnet_name : null
      ssh_key_name    = "k3s-cluster-ssh-key"
      labels          = sp.labels
      ipv4_enabled    = sp.ipv4_enabled
      ipv6_enabled    = sp.ipv4_enabled ? false : true
      cloud_init_file = sp.cloud_init_file
    }
  }
}

module "hcloud_networks" {
  for_each         = { for n in var.hcloud_networks : n.name => n }
  source           = "../../modules/hcloud_networking"
  network_name     = each.value.name
  network_zone     = "eu-central"
  network_ip_range = each.value.ip_range
  subnets          = each.value.subnets
}

module "hcloud_server_pools" {
  for_each     = { for n in local.server_pools : n.name => n }
  source       = "../../modules/hcloud_server_pool"
  name         = each.key
  location     = "fsn1"
  image        = each.value.image
  node_type    = each.value.node_type
  server_count = each.value.count
  ssh_key_id   = hcloud_ssh_key.this[each.value.ssh_key_name].id
  ipv4_enabled = each.value.ipv4_enabled
  ipv6_enabled = each.value.ipv6_enabled
  subnet_id    = each.value.network_name == null || each.value.subnet_name == null ? null : module.hcloud_networks[each.value.network_name].subnets[each.value.subnet_name].id
  user_data = templatefile("${path.module}/files/${each.value.cloud_init_file}", {
    netbird_setup_key = var.netbird_setup_key
  })
  depends_on = [module.hcloud_networks]
  labels = merge(
    {
      "server-pool-name" = each.key,
      "managed-by" : "Terraform"
    },
    each.value.labels
  )
}

resource "hcloud_ssh_key" "this" {
  for_each   = { for k in var.hcloud_ssh_keys : k.name => k }
  name       = each.value.name
  public_key = file(each.value.public_key_path)
}
