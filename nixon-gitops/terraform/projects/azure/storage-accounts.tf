
resource "azurerm_storage_account" "default" {
  for_each                        = { for x in var.azure_storage_accounts : x.name => x }
  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = azurerm_resource_group.default[each.value.resource_group_name].location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  access_tier                     = "Cold"
  tags                            = var.azure_common_labels
}
