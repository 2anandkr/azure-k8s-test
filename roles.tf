data "azurerm_resource_group" "secondary" {
  name = var.secondary_resource_group
}

resource "azurerm_role_assignment" "secondary_rg" {
  scope                = data.azurerm_resource_group.secondary.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.cluster.identity[0].principal_id
}