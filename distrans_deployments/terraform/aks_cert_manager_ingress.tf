# loading k8s namespaces manifests
data "kubectl_path_documents" "namespace_manifest" {
  pattern = "./k8s_namespace_manifest/*.yaml"
  vars = {
    aks_namespace        = var.aks_namespace,
  }
}

# applying namespace manifest on aks
resource "kubectl_manifest" "aks_namespace_manifest" {
  for_each  = toset(data.kubectl_path_documents.namespace_manifest.documents)
  yaml_body = each.value
}

# Install Nginx Ingress using Helm Chart
resource "helm_release" "helm_nginx" {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = var.aks_namespace
  version    = "4.1.3"

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = var.project_name_prefix
    type  = "string"
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
    type  = "string"
  }

  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.kubernetes\\.io/os"
    value = "linux"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
    type  = "string"
  }

  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
    type  = "string"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  depends_on = [
    kubectl_manifest.aks_namespace_manifest
  ]
}

# Install cert-manager using Helm Chart
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = var.aks_namespace
  version    = "v1.8.0"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
    type  = "string"
  }

  depends_on = [
    kubectl_manifest.aks_namespace_manifest
  ]
}

# loading k8s manifests
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

  depends_on = [
    kubectl_manifest.aks_namespace_manifest,
    helm_release.cert_manager
  ]
}
