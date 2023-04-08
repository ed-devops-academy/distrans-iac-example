resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${random_pet.prefix.id}-aks"
  llocation           = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  dns_prefix          = var.project_name_prefix

  default_node_pool {
    name            = "default"
    node_count      = var.cluster_nodes_quantity
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}
