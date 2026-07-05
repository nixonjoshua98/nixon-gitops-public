resource "hcloud_network" "network" {
  name     = var.network_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "subnets" {
  for_each      = var.subnets
  network_id    = hcloud_network.network.id
  type          = "cloud"
  network_zone  = var.network_zone
  ip_range      = each.value.ip_range
}