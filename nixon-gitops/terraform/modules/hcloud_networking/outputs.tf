output "subnets" {
  value = {
    for k, subnet in hcloud_network_subnet.subnets : k => {
      id = subnet.id
    }
  }
}