# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/poseidon/terraform-render-bootstrap.git"

  cluster_name = var.cluster_name
  api_servers  = [for ip in hcloud_server.controller_server.*.ipv4_address : format("%s.nip.io", ip)]
  etcd_servers = [for ip in hcloud_server.controller_server.*.ipv4_address : format("%s.nip.io", ip)]

  networking = var.networking

  # only effective with Calico networking
  network_encapsulation = "vxlan"
  network_mtu           = "1450"

  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  cluster_domain_suffix = var.cluster_domain_suffix
  enable_reporting      = var.enable_reporting
  enable_aggregation    = var.enable_aggregation
}

