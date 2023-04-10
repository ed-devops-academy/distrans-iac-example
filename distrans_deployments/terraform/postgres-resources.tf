resource "azurerm_virtual_network" "postgres_vnet" {
  name                = "${var.project_name_prefix}-pg-vnet"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_network_security_group" "postgres_nsg" {
  name                = "${var.project_name_prefix}-pg-nsg"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name

  security_rule {
    name                       = "AllowTCPIn"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "postgres_subnet" {
  name                = "${var.project_name_prefix}-pg-subnet"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  address_prefixes    = ["10.0.2.0/24"]
  service_endpoints   = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "postgres_nsg_snet_link" {
  subnet_id                 = azurerm_subnet.postgres_subnet.id
  network_security_group_id = azurerm_network_security_group.postgres_nsg.id
}

resource "azurerm_private_dns_zone" "postgres_dns_zone" {
  name                = "${var.project_name_prefix}-pdz.postgres.database.azure.com"
  resource_group_name = var.azurerm_resource_group_name

  depends_on = [azurerm_subnet_network_security_group_association.postgres_nsg_snet_link]
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_vnet_link" {
  name                  = "${var.project_name_prefix}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.postgres_vnet.id
  resource_group_name   = var.azurerm_resource_group_name
}


resource "azurerm_postgresql_flexible_server" "postgres_server" {
  name                   = "${var.project_name_prefix}-pg-server"
  location               = var.azurerm_location
  resource_group_name    = var.azurerm_resource_group_name
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns_zone.id
  administrator_login    = "adminTerraform"
  administrator_password = random_password.pass.result
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_vnet_link]
}
