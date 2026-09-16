# Off by default (see var.enable_tetragon). Tetragon's process/network
# hooks need a kernel with BTF support and the standard eBPF JIT enabled.
# Most managed CI runners are fine, but some sandboxes are not, so the CI
# pipeline in this lab exercises Falco only and this is here to show the
# pattern, and to run locally or against a real cluster with
# `-var enable_tetragon=true`.

resource "helm_release" "tetragon" {
  count = var.enable_tetragon ? 1 : 0

  name       = "tetragon"
  repository = "https://helm.cilium.io"
  chart      = "tetragon"
  version    = var.tetragon_chart_version
  namespace  = kubernetes_namespace.detection_lab.metadata[0].name

  set {
    name  = "tetragon.exportAllowList"
    value = "{}"
  }
}
