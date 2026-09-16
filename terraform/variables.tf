variable "kubeconfig_path" {
  description = "Path to the kubeconfig for the target cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kube context to use. Leave empty to use the current context."
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace the detection stack is deployed into."
  type        = string
  default     = "detection-lab"
}

variable "falco_chart_version" {
  description = "Falco Helm chart version. Pin this deliberately, do not float on latest."
  type        = string
  default     = "4.7.5"
}

variable "enable_tetragon" {
  description = "Whether to also deploy Tetragon alongside Falco. Off by default so the lab works on constrained CI runners; the README explains the kernel requirements for turning it on."
  type        = bool
  default     = false
}

variable "tetragon_chart_version" {
  description = "Tetragon Helm chart version."
  type        = string
  default     = "1.2.0"
}
