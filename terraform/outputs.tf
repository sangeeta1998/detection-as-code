output "namespace" {
  description = "Namespace the detection stack was deployed into."
  value       = kubernetes_namespace.detection_lab.metadata[0].name
}

output "falco_release_name" {
  value = helm_release.falco.name
}

output "falco_release_status" {
  value = helm_release.falco.status
}
