#locals {
#  official_images   = []
#  is_official_image = contains(local.official_images, var.os_image)
#}
#
## Controller Instance DNS records
#resource "digitalocean_record" "controllers" {
#  count = var.controller_count
#
#  # DNS zone where record should be created
#  domain = var.dns_zone
#
#  # DNS record (will be prepended to domain)
#  name = var.cluster_name
#  type = "A"
#  ttl  = 300
#
#  # IPv4 addresses of controllers
#  value = digitalocean_droplet.controllers.*.ipv4_address[count.index]
#}
#
## Discrete DNS records for each controller's private IPv4 for etcd usage
#resource "digitalocean_record" "etcds" {
#  count = var.controller_count
#
#  # DNS zone where record should be created
#  domain = var.dns_zone
#
#  # DNS record (will be prepended to domain)
#  name = "${var.cluster_name}-etcd${count.index}"
#  type = "A"
#  ttl  = 300
#
#  # private IPv4 address for etcd
#  value = digitalocean_droplet.controllers.*.ipv4_address_private[count.index]
#}
#
## Controller droplet instances
#resource "digitalocean_droplet" "controllers" {
#  count = var.controller_count
#
#  name   = "${var.cluster_name}-controller-${count.index}"
#  region = var.region
#
#  image = var.os_image
#  size  = var.controller_type
#
#  # network
#  vpc_uuid           = digitalocean_vpc.network.id
#  # TODO: Only official DigitalOcean images support IPv6
#  ipv6 = false
#
#  user_data = data.ct_config.controller-ignitions.*.rendered[count.index]
#  ssh_keys  = var.ssh_fingerprints
#
#  tags = [
#    digitalocean_tag.controllers.id,
#  ]
#
#  lifecycle {
#    ignore_changes = [user_data]
#  }
#}
#
## Tag to label controllers
#resource "digitalocean_tag" "controllers" {
#  name = "${var.cluster_name}-controller"
#}

resource "hcloud_server" "controller_server" {
  count    = var.controller_count
  name     = "${var.cluster_name}-controller-${count.index}"
  ssh_keys = [hcloud_ssh_key.ssh_admin_key.id]

  depends_on = [hcloud_network_subnet.etcd_subnet]

  network {
    network_id = hcloud_network.etcd_network.id
    ip         = cidrhost(var.etcd_network_cidr, count.index + 2)
  }

  # boot into rescue OS
  rescue = "linux64"
  # dummy value for the OS because Flatcar is not available

  image       = var.os_image
  server_type = var.controller_type
  datacenter  = var.datacenter
  connection {
    host    = self.ipv4_address
    timeout = "3m"
  }

  provisioner "file" {
    content     = data.ct_config.controller-ignitions.*.rendered[count.index]
    destination = "/root/ignition.json"
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "apt update",
      "apt install -y gawk",
      "curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/kinvolk/init/flatcar-master/bin/flatcar-install",
      "chmod +x flatcar-install",
      "./flatcar-install -s -i /root/ignition.json",
      "shutdown -r +1",
    ]
  }

  # optional:
  provisioner "remote-exec" {
    connection {
      host    = self.ipv4_address
      timeout = "3m"
      user    = "core"
    }

    inline = [
      "sudo hostnamectl set-hostname ${self.name}",
    ]
  }
}

# Controller Ignition configs
data "ct_config" "controller-ignitions" {
  count    = var.controller_count
  content  = data.template_file.controller-configs.*.rendered[count.index]
  strict   = true
  snippets = var.controller_snippets
}

# Controller Container Linux configs
data "template_file" "controller-configs" {
  count = var.controller_count

  template = file("${path.module}/cl/controller.yaml")

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    hostname = "controller-${count.index}"
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${cidrhost(var.etcd_network_cidr, 2)}.nip.io"
    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster   = join(",", data.template_file.etcds.*.rendered)
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
    ssh_keys               = jsonencode([hcloud_ssh_key.ssh_admin_key.public_key])
  }
}

data "template_file" "etcds" {
  count    = var.controller_count
  template = "etcd${count.index}=https://${cidrhost(var.etcd_network_cidr, count.index + 2)}.nip.io:2380"
}


