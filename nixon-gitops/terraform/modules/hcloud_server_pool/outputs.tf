output "servers" {
  value = [
    for s in hcloud_server.servers : {
      id            = s.id
      name          = s.name
      ipv4_address  = s.ipv4_address == "" ? null : s.ipv4_address
      ipv6_address  = s.ipv6_address == "" ? null : s.ipv6_address
      labels        = s.labels
    }
  ]
}
