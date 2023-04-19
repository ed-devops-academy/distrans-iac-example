terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Initialize Helm
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
  }
}

# Initialize kubectl
provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}
