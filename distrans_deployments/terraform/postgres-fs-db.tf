resource "azurerm_postgresql_flexible_server_database" "postgres_server_database" {
  name      = "${var.project_name_prefix}-pg-db"
  server_id = azurerm_postgresql_flexible_server.postgres_server.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}
