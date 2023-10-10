# Create virtual network
resource "azurerm_virtual_network" "app_vm_network" {
  name                = "${var.client_application_name_prefix}VMVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
}

# Create subnet
resource "azurerm_subnet" "app_vm_subnet" {
  name                 = "${var.client_application_name_prefix}VMSubnet"
  resource_group_name  = var.azurerm_resource_group_name
  virtual_network_name = azurerm_virtual_network.app_vm_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "app_vm_public_ip" {
  name                = "${var.client_application_name_prefix}VMPublicIP"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "app_vm_nsg" {
  name                = "${var.client_application_name_prefix}VMNetworkSecurityGroup"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
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

  security_rule {
    name                       = "prometheus_metric"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9182"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "app_vm_nic" {
  name                = "${var.client_application_name_prefix}VMNIC"
  location            = var.azurerm_location
  resource_group_name = var.azurerm_resource_group_name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.app_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_vm_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "app_vm_sg_nic_connection" {
  network_interface_id      = azurerm_network_interface.app_vm_nic.id
  network_security_group_id = azurerm_network_security_group.app_vm_nsg.id
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
resource "azurerm_storage_account" "app_vm_storage_account" {
  name                     = "${random_id.random_id.hex}appvm"
  location                 = var.azurerm_location
  resource_group_name      = var.azurerm_resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                  = "${var.client_application_name_prefix}VM"
  location              = var.azurerm_location
  resource_group_name   = var.azurerm_resource_group_name
  network_interface_ids = [azurerm_network_interface.app_vm_nic.id]
  size                  = "Standard_DS1_v2"

  computer_name  = var.app_vm_hostname
  admin_username = var.app_vm_username
  admin_password = random_password.password.result

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.app_vm_storage_account.primary_blob_endpoint
  }
}

resource "random_pet" "prefix" {
  prefix = var.client_application_name_prefix
  length = 1
}

data "template_file" "setups" {
  template = file("./wind10_server_scripts/setups.ps1")
  vars = {
    RepoPAT       = var.azure_repo_pat,
    FirewallIP    = azurerm_windows_virtual_machine.app_vm.public_ip_address,
    ServerName    = var.app_vm_hostname,
    InstallerPath = var.app_vm_prometheus_exporter_installer_url,
    Collectors    = var.app_vm_prometheus_collectors
  }

  depends_on = [azurerm_windows_virtual_machine.app_vm]
}

resource "azurerm_virtual_machine_extension" "app_vm_web_setups" {
  name                       = "${random_pet.prefix.id}-setups"
  virtual_machine_id         = azurerm_windows_virtual_machine.app_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
  {    
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.setups.rendered)}')) | Out-File -filepath setups.ps1\" && powershell -ExecutionPolicy Unrestricted -File setups.ps1 -RepoPAT ${var.azure_repo_pat} -FirewallIP ${azurerm_windows_virtual_machine.app_vm.public_ip_address} -ServerName ${var.app_vm_hostname} -InstallerPath ${var.app_vm_prometheus_exporter_installer_url} -Collectors ${var.app_vm_prometheus_collectors}" 
  }
  
  SETTINGS

  depends_on = [azurerm_windows_virtual_machine.app_vm]
}
