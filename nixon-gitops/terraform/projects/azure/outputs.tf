output "key_vault_credentials" {
  value = {
    for name, vault in module.key_vaults : name => {
      vault_uri     = vault.vault_uri
      client_id     = module.application_bundles["k3s-cluster-application"].application_client_id
      client_secret = module.application_bundles["k3s-cluster-application"].client_secrets["keyvault"].value
    }
  }
  sensitive = true
}

output "container_registry_dockerconfigs" {
  value = {
    for name, registry in module.container_registries : name => {
      auths = {
        for login_server in [registry.login_server] : login_server => {
          auth = base64encode("${module.application_bundles["k3s-cluster-application"].application_client_id}:${module.application_bundles["k3s-cluster-application"].client_secrets["container-registry"].value}")
        }
      }
    }
  }
  sensitive = true
}