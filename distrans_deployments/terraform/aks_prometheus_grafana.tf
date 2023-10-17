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
  values = [templatefile("./prometheus/install_values.yaml", {
    ws_public_ip         = azurerm_windows_virtual_machine.app_vm.public_ip_address,
    prometheus_namespace = var.aks_prometheus_namespace
  })]

  timeout = 2000
}

data "external" "prometheus_source_public_ip" {
  program = ["bash", "./prometheus/get_pro_service_ip.sh"]

  query = {
    kube_config = "${azurerm_kubernetes_cluster.aks_cluster.kube_config_raw}"
  }

  depends_on = [helm_release.prometheus]
}

resource "kubernetes_config_map" "grafana-datasource-distrans" {
  metadata {
    name      = "grafana-datasource-distrans"
    namespace = kubernetes_namespace.prometheus_namespace.id

    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "distrans-prometheus-datasource.yaml" = templatefile("./prometheus/grafana_datasource.yaml", {
      promethues_loadbalancer_ip = "${data.external.prometheus_source_public_ip.result.ip}"
    })
  }

  depends_on = [helm_release.prometheus, data.external.prometheus_source_public_ip]
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
