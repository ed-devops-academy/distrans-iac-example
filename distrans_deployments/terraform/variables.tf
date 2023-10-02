variable "project_name_prefix" {
  type        = string
  default     = "distrans"
  description = "Name of the project to use as prefix for resources."
}

variable "client_application_name_prefix" {
  type        = string
  default     = "superCheapApp"
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
  default     = 2
  description = "Quantity of nodes for the Azure Kubernete Cluster."
}

variable "postgres_server_administrator_login" {
  type        = string
  default     = "trx"
  description = "Login name to be used as administrator of the postgres server."
}

variable "postgres_server_administrator_password" {
  type        = string
  default     = "trx123"
  description = "Password of the administrator of the postgres server."
}

variable "aks_namespace" {
  type        = string
  default     = "distrans"
  description = "Default AKS namespace where create resources."
}

variable "aks_argocd_namespace" {
  type        = string
  default     = "argocd"
  description = "Default AKS namespace for ArgoCD resources."
}

variable "aks_prometheus_namespace" {
  type        = string
  default     = "prometheus"
  description = "Default AKS namespace for Prometheus/Grafana resources."
}

variable "organization_email" {
  type        = string
  default     = "eduardo.miguel@musala.com"
  description = "Organization email to use AKS ClusterIssuer on tls setup."
}

variable "app_vm_hostname" {
  type        = string
  default     = "superCheapApp"
  description = "Hostname of the virtual machine agent resource."
}

variable "app_vm_username" {
  type        = string
  default     = "azureuser"
  description = "Username of the virtual machine agent resource."
}

variable "azure_repo_pat" {
  type        = string
  default     = "IntroduceRepoPATPlease"
  description = "Azure DevOps Repo PAT for vm app agent configuration."
}



