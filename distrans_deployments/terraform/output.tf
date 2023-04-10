output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}

output "azurerm_postgresql_flexible_server" {
  value = azurerm_postgresql_flexible_server.postgres_server.name
}

output "postgresql_flexible_server_database_name" {
  value = azurerm_postgresql_flexible_server_database.postgres_server_database.name
}

output "postgresql_flexible_server_admin_password" {
  sensitive = true
  value     = azurerm_postgresql_flexible_server.postgres_server.administrator_password
}
