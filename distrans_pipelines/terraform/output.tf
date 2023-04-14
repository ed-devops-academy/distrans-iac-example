output "agent_virtual_machine_name" {
  value = azurerm_linux_virtual_machine.agent_vm.name
}

output "agent_public_ip_address" {
  value = azurerm_linux_virtual_machine.agent_vm.public_ip_address
}

output "agent_admin_username" {
  value = azurerm_linux_virtual_machine.agent_vm.admin_username
}

output "tls_private_key" {
  value     = tls_private_key.agent_vm_ssh.private_key_pem
  sensitive = true
}
