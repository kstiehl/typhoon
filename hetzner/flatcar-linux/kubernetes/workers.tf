## Worker DNS records
#resource "digitalocean_record" "workers-record-a" {
#  count = var.worker_count
#
#  # DNS zone where record should be created
#  domain = var.dns_zone
#
#  name  = "${var.cluster_name}-workers"
#  type  = "A"
#  ttl   = 300
#  value = digitalocean_droplet.workers.*.ipv4_address[count.index]
#}
#
#resource "digitalocean_record" "workers-record-aaaa" {
#  # only official DigitalOcean images support IPv6
#  count = local.is_official_image ? var.worker_count : 0
#
#  # DNS zone where record should be created
#  domain = var.dns_zone
#
#  name  = "${var.cluster_name}-workers"
#  type  = "AAAA"
#  ttl   = 300
#  value = digitalocean_droplet.workers.*.ipv6_address[count.index]
#}
#
## Worker droplet instances
#resource "digitalocean_droplet" "workers" {
#  count = var.worker_count
#
#  name   = "${var.cluster_name}-worker-${count.index}"
#  region = var.region
#
#  image = var.os_image
#  size  = var.worker_type
#
#  # network
#  vpc_uuid = digitalocean_vpc.network.id
#  # only official DigitalOcean images support IPv6
#  ipv6 = local.is_official_image
#
#  user_data = data.ct_config.worker-ignition.rendered
#  ssh_keys  = var.ssh_fingerprints
#
#  tags = [
#    digitalocean_tag.workers.id,
#  ]
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
#
## Tag to label workers
#resource "digitalocean_tag" "workers" {
#  name = "${var.cluster_name}-worker"
#}

resource "hcloud_server" "worker_server" {
  count    = var.worker_count
  name     = "${var.cluster_name}-worker-${count.index}"
  ssh_keys = [hcloud_ssh_key.ssh_admin_key.id]
  # boot into rescue OS

  rescue = "linux64"
  # dummy value for the OS because Flatcar is not available
  image       = var.os_image
  server_type = var.worker_type
  datacenter  = var.datacenter
  connection {
    host    = self.ipv4_address
    timeout = "3m"
  }
  provisioner "file" {
    content     = data.ct_config.worker-ignition.*.rendered[count.index]
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

# Worker Ignition config
data "ct_config" "worker-ignition" {
  content  = data.template_file.worker-config.rendered
  strict   = true
  snippets = var.worker_snippets
}

# Worker Container Linux config
data "template_file" "worker-config" {
  template = file("${path.module}/cl/worker.yaml")

  vars = {
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
    ssh_keys               = jsonencode([hcloud_ssh_key.ssh_admin_key.public_key])
  }
}

