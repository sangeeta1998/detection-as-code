# Both providers read from the standard kubeconfig by default, which is
# populated by `kind` in CI (see .github/workflows/ci.yml) or by your own
# kubeconfig locally. Nothing cloud-specific is required to run this.

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}
