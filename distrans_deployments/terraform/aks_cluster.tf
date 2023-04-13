resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.project_name_prefix}-aks-subnet"
  resource_group_name  = var.azurerm_resource_group_name
  virtual_network_name = azurerm_virtual_network.postgres_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}


resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.project_name_prefix}-aks"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  dns_prefix          = var.project_name_prefix

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr = "10.0.4.0/24"
    dns_service_ip = "10.0.4.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  default_node_pool {
    name            = "default"
    node_count      = var.cluster_nodes_quantity
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}
