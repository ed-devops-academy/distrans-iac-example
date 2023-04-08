variable "project_name_prefix" {
  type        = string
  default     = "distrans"
  description = "Name of the project to use as prefix for resources."
}
variable "azurerm_resource_group_name" {
  type        = string
  default     = "1-b13ea3a5-playground-sandbox"
  description = "Name of the predefined resource group to use."
}
variable "azurerm_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "cluster_nodes_quantity" {
  type        = number
  default     = 6
  description = "Quantity of nodes for the Azure Kubernete Cluster."
}


