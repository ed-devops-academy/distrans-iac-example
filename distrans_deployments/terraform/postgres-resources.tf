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
    name                       = "AllowPostgresPortIn"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [5432, 6432]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "postgres_subnet" {
  name                 = "${var.project_name_prefix}-pg-subnet"
  resource_group_name  = var.azurerm_resource_group_name
  virtual_network_name = azurerm_virtual_network.postgres_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

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
  name                = "${var.project_name_prefix}dns.postgres.database.azure.com"
  resource_group_name = var.azurerm_resource_group_name

  depends_on = [azurerm_subnet_network_security_group_association.postgres_nsg_snet_link]
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_vnet_link" {
  name                  = "${var.project_name_prefix}pglink"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.postgres_vnet.id
  resource_group_name   = var.azurerm_resource_group_name
}


resource "azurerm_postgresql_flexible_server" "postgres_server" {
  name                   = "${var.project_name_prefix}pgserver"
  location               = var.azurerm_location
  resource_group_name    = var.azurerm_resource_group_name
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns_zone.id
  administrator_login    = var.postgres_server_administrator_login
  administrator_password = var.postgres_server_administrator_password
  # zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_vnet_link]
}
