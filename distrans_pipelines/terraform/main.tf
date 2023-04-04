# Create virtual network
resource "azurerm_virtual_network" "agent_network" {
  name                = "${var.project_name_prefix}AgentVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
}

# Create subnet
resource "azurerm_subnet" "agent_subnet" {
  name                 = "${var.project_name_prefix}AgentSubnet"
  resource_group_name  = var.azurerm_resource_group_name
  virtual_network_name = azurerm_virtual_network.agent_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "agent_public_ip" {
  name                = "${var.project_name_prefix}AgentPublicIP"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "agent_nsg" {
  name                = "${var.project_name_prefix}AgentNetworkSecurityGroup"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "agent_nic" {
  name                = "${var.project_name_prefix}AgentNIC"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.agent_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "agent_sg_nic_connection" {
  network_interface_id      = azurerm_network_interface.agent_nic.id
  network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.azurerm_resource_group_name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "agent_storage_account" {
  name                     = "${var.project_name_prefix}agentstorage"
  location                 = var.azurerm_location
  resource_group_name      = var.azurerm_resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "agent_vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                  = "${var.project_name_prefix}${var.agent_vm_name}"
  location              = var.azurerm_location
  resource_group_name   = var.azurerm_resource_group_name
  network_interface_ids = [azurerm_network_interface.agent_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "agentOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = var.agent_vm_hostname
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.agent_vm_username
    public_key = tls_private_key.agent_vm_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.agent_storage_account.primary_blob_endpoint
  }

}

resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name_prefix}acr"
  resource_group_name = var.azurerm_resource_group_name
  location            = var.azurerm_location
  sku                 = "Basic"
  admin_enabled       = true
}
