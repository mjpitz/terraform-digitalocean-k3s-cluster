locals {
  mapped_nodes = flatten([
    for node_pool in var.node_pools : [
      for i in range(0, node_pool.count) : {
        name = format("%s-agent-%s-%d", var.cluster_name, node_pool.name, i)
        image = node_pool.image
        size = node_pool.size
        version = node_pool.version
      }
    ]
  ])
}

resource "tls_private_key" "agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "digitalocean_ssh_key" "agent" {
  name = "${var.cluster_name}-agent"
  public_key = tls_private_key.agent.public_key_openssh
}

resource "digitalocean_droplet" "agents" {
  depends_on = [
    digitalocean_droplet.servers,
    null_resource.server_startup,
  ]

  # expand node pools to nodes
  count = length(local.mapped_nodes)

  name = local.mapped_nodes[count.index].name
  region = var.region
  image = local.mapped_nodes[count.index].image
  size = local.mapped_nodes[count.index].size

  vpc_uuid = digitalocean_vpc.vpc.id

  ssh_keys = [
    digitalocean_ssh_key.agent.id,
  ]

  tags = [
    "k3s",
    format("k3s-%s", var.cluster_name),
    format("k3s-%s-agent", var.cluster_name),
  ]

  connection {
    user = "root"
    host = self.ipv4_address
    private_key = tls_private_key.agent.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/rancher/k3s"
    ]
  }

  provisioner "file" {
    destination = "/etc/rancher/k3s/config.yaml"
    content = templatefile("${path.module}/templates/k3s-agent.yaml", {
      token = random_string.token.result,
      server = digitalocean_loadbalancer.server.ip,
    })
  }

  provisioner "file" {
    destination = "/usr/local/bin/install-k3s.sh"
    content = templatefile("${path.module}/templates/install-k3s.sh", {
      version = local.mapped_nodes[count.index].version,
      role = "agent"
    })
  }

  provisioner "remote-exec" {
    inline = [
      "bash /usr/local/bin/install-k3s.sh",
    ]
  }
}
