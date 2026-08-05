resource "azurerm_key_vault" "this" {
  for_each = { for x in var.azure_key_vaults : x.name => x }

  name                       = each.value.name
  resource_group_name        = each.value.resource_group_name
  location                   = azurerm_resource_group.default[each.value.resource_group_name].location
  tenant_id                  = var.azure_tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  tags                       = var.azure_common_labels
}
