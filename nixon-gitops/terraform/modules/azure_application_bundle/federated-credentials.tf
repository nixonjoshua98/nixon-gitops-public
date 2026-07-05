locals {
  federated_credential_list = flatten([
    for credential in var.federated_credentials : [
      for branch in credential.branches : {
        key          = format("github-%s-%s-%s", credential.organisation, credential.repository, branch)
        organisation = credential.organisation
        repository   = credential.repository
        branch       = branch
        audience     = ["api://AzureADTokenExchange"]
      }
    ]
  ])

  federated_credential_map = {
    for item in local.federated_credential_list : item.key => {
      organisation = item.organisation
      repository   = item.repository
      branch       = item.branch
      audience     = item.audience
    }
  }

  federated_subjects = {
    for key, credential in local.federated_credential_map : key => format("repo:%s/%s:ref:refs/heads/%s", credential.organisation, credential.repository, credential.branch)
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credential_map

  application_id = azuread_application.this.id
  display_name   = each.key
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = local.federated_subjects[each.key]
  audiences      = each.value.audience
}
