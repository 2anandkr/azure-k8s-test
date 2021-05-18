
# resource "azurerm_kubernetes_cluster" "cluster" {
#   name                = "${var.prefix}-aks"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   dns_prefix          = "${var.prefix}-aks"

#   default_node_pool {
#     name       = "default"
#     node_count = var.cluster_vm_min_count
#     vm_size    = var.cluster_vm_size
#     type       = "VirtualMachineScaleSets"
#     # Availability Zones across which the Node Pool should be spread
#     # availability_zones  = ["1", "2"]
#     enable_auto_scaling = true
#     min_count           = var.cluster_vm_min_count
#     max_count           = var.cluster_vm_max_count

#     # Required for advanced networking
#     vnet_subnet_id = azurerm_subnet.subnet_1.id
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   role_based_access_control {
#     azure_active_directory {
#       managed                = true
#       admin_group_object_ids = var.cluster_azure_ad_groups
#       tenant_id              = var.cluster_azure_ad_tenant_id
#     }
#     enabled = true
#   }

#   network_profile {
#     network_plugin    = "azure"
#     load_balancer_sku = "standard"
#     network_policy    = "calico"
#   }

#   tags = {
#     Environment = var.prefix
#   }
# }
