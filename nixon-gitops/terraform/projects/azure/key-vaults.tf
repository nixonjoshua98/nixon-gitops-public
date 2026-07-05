module "key_vaults" {
  source = "../../modules/azure_vault"

  for_each = { for x in var.azure_key_vaults : x.name => x }

  tenant_id           = var.azure_tenant_id
  resource_group_name = each.value.resource_group_name
  location            = azurerm_resource_group.default[each.value.resource_group_name].location
  vault_name          = each.value.name
  tags                = var.azure_common_labels
}
