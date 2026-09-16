resource "helm_release" "falco" {
  name       = "falco"
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = var.falco_chart_version
  namespace  = kubernetes_namespace.detection_lab.metadata[0].name

  # Modern eBPF probe rather than the older kernel module driver, so this
  # runs on stock GitHub Actions / kind nodes without building a kernel
  # module against the runner's kernel.
  set {
    name  = "driver.kind"
    value = "modern_ebpf"
  }

  # JSON output on stdout is what tests/validate_alerts.py greps out of the
  # pod logs. In a real deployment you'd point outputs.http instead at
  # Falcosidekick or your SIEM; stdout keeps this lab dependency-free.
  set {
    name  = "falco.jsonOutput"
    value = "true"
  }

  set {
    name  = "falco.jsonIncludeOutputProperty"
    value = "true"
  }

  set {
    name  = "falco.logLevel"
    value = "info"
  }

  # Layer our own detection rules (attack-justified rules for the two
  # scenarios this lab exercises) on top of the shipped default rule set,
  # rather than replacing it.
  values = [
    file("${path.module}/../detection-rules/custom_rules.yaml")
  ]
}
