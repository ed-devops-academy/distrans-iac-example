azurerm_resource_group_name              = "1-73be3bb6-playground-sandbox"
azurerm_location                         = "eastus"
project_name_prefix                      = "distrans"
cluster_nodes_quantity                   = 2
aks_namespace                            = "distrans"
aks_argocd_namespace                     = "argocd"
app_vm_prometheus_exporter_installer_url = "https://github.com/prometheus-community/windows_exporter/releases/download/v0.24.0/windows_exporter-0.24.0-amd64.msi"
app_vm_prometheus_collectors             = "cpu,cs,logical_disk,net,os,service,system,textfile,memory,iis"