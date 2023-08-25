resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = var.aks_argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.43.7"
  namespace  = var.aks_argocd_namespace
  timeout    = "1200"
  values     = [templatefile("./argocd/install_values.yaml", {})]

  depends_on = [
    kubernetes_namespace.argocd_namespace
  ]
}