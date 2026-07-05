
resource "azurerm_resource_group" "default" {
  for_each = { for x in var.azure_resource_groups : x.name => x }
  name     = each.value.name
  location = "uksouth"
  tags     = var.azure_common_labels
}
