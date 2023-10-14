resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    name = var.aks_prometheus_namespace
  }
}


resource "helm_release" "prometheus" {
  depends_on       = [kubernetes_namespace.prometheus_namespace, azurerm_windows_virtual_machine.app_vm]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.prometheus_namespace.id
  create_namespace = true
  version          = "51.2.0"
  values           = [templatefile("./prometheus/install_values.yaml", { ws_public_ip = azurerm_windows_virtual_machine.app_vm.public_ip_address })]
  timeout          = 2000
}

resource "kubernetes_config_map" "grafana-dashboards-distrans" {
  metadata {
    name      = "grafana-dashboard-distrans"
    namespace = kubernetes_namespace.prometheus_namespace.id

    labels = {
      grafana_dashboard = 1
    }

    annotations = {
      k8s-sidecar-target-directory = "/tmp/dashboards/distrans"
    }
  }

  data = {
    "distrans-dashboard.json" = file("./prometheus/grafana_dashboard.json")
  }

  depends_on = [helm_release.prometheus]
}
