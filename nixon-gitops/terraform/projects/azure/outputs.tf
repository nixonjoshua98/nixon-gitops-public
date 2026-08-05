locals {
  application_client_id = module.application_bundles["k3s-cluster-application"].application_client_id
  registry_secret       = module.application_bundles["k3s-cluster-application"].client_secrets["container-registry"].value

  dockerconfig_auths = {
    for name, registry in module.container_registries : registry.login_server => {
      auth = base64encode("${local.application_client_id}:${local.registry_secret}")
    }
  }
}

output "dockerconfig" {
  value     = jsonencode({ auths = local.dockerconfig_auths })
  sensitive = true
}