resource "hcloud_network" "etcd_network" {
  name     = "etcd-network"
  ip_range = "10.0.15.0/24"
}


resource "hcloud_network_subnet" "etcd_subnet" {
  network_id   = hcloud_network.etcd_network.id
  type         = "cloud"
  ip_range     = "10.0.15.0/24"
  network_zone = "eu-central"
}
