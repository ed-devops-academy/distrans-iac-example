resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    name = var.aks_prometheus_namespace
  }
}


resource "helm_release" "prometheus" {
  depends_on       = [kubernetes_namespace.prometheus_namespace]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.prometheus_namespace.id
  create_namespace = true
  version          = "51.2.0"
  values           = [templatefile("./prometheus/install_values.yaml", {})]
  timeout          = 2000
}
