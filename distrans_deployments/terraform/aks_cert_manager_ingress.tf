# Add Kubernetes Stable Helm charts repo
data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

# Add Kubernetes jetstack Helm charts repo
data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

# Install Nginx Ingress using Helm Chart
resource "helm_release" "helm_nginx" {
  name       = "ingress-nginx"
  repository = data.helm_repository.stable.url
  chart      = "ingress-nginx/ingress-nginx"
  namespace  = var.aks_namespace

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = var.project_name_prefix
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.aks_nginx_ingress_public_ip.ip_address
  }
}

# Install cert-manager using Helm Chart
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = data.helm_repository.jetstack.url
  chart      = "cert-manager"
  namespace  = var.aks_namespace

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
}

# loading k8s manifest
data "kubectl_path_documents" "manifests" {
    pattern = "./k8s_manifests/*.yaml"
    vars = {
        organization_email = var.organization_email
    }
}

# applying manifest on aks
resource "kubectl_manifest" "aks_manifests" {
    for_each  = toset(data.kubectl_path_documents.manifests.documents)
    yaml_body = each.value
}
