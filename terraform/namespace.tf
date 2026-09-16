resource "kubernetes_namespace" "detection_lab" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of" = "detection-as-code-lab"
      "pod-security.kubernetes.io/enforce" = "privileged"
      # Falco and Tetragon both need elevated host access (kernel probes,
      # /proc, /sys) to observe syscalls, so this namespace is intentionally
      # exempted from restricted Pod Security Admission. Everything the
      # attack simulations run against lives in its own separate namespace,
      # created in attack-simulations/namespace.yaml, which stays restricted.
    }
  }
}
