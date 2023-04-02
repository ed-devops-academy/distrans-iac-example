output "agent_virtual_machine_name" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.name
}

output "agent_public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}