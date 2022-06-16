variable "cluster_name" {
  type        = string
  description = "Unique cluster name "
}

variable "datacenter" {
  type        = string
  description = "the hetzner datacenter in which this will be setup"
}

# instances

variable "controller_count" {
  type        = number
  description = "Number of controllers"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "Number of workers"
  default     = 1
}

variable "controller_type" {
  type        = string
  description = "Hetzner VM type"
  default     = "cx21"
}

variable "worker_type" {
  type        = string
  description = "Hetzner VM type"
  default     = "cx21"
}

variable "os_image" {
  type        = string
  description = "Flatcar Linux image for instances (e.g. custom-image-id)"
}

variable "controller_snippets" {
  type        = list(string)
  description = "Controller Container Linux Config snippets"
  default     = []
}

variable "worker_snippets" {
  type        = list(string)
  description = "Worker Container Linux Config snippets"
  default     = []
}

# configuration

variable "ssh_public_key_file" {
  type        = string
  description = "the path to the admin public key file"
}

variable "ssh_fingerprints" {
  # TODO Check whether this is needed maybe we can use the attribute form the hcloud resource
  type        = list(string)
  description = "SSH public key fingerprints. (e.g. see `ssh-add -l -E md5`)"
}

variable "networking" {
  type        = string
  description = "Choice of networking provider (flannel, calico, or cilium)"
  default     = "cilium"
}

variable "pod_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign Kubernetes pods"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD
  default     = "10.3.0.0/16"
}

variable "enable_reporting" {
  type        = bool
  description = "Enable usage or analytics reporting to upstreams (Calico)"
  default     = false
}

variable "enable_aggregation" {
  type        = bool
  description = "Enable the Kubernetes Aggregation Layer"
  default     = true
}

# unofficial, undocumented, unsupported

variable "cluster_domain_suffix" {
  type        = string
  description = "Queries for domains with the suffix will be answered by coredns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  default     = "cluster.local"
}

