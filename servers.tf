resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "digitalocean_ssh_key" "server" {
  name = "${var.cluster_name}-server"
  public_key = tls_private_key.server.public_key_openssh
}

resource "local_file" "id_do" {
  filename = "${path.module}/id_do"
  file_permission = "0600"
  content_base64 = base64encode(tls_private_key.server.private_key_pem)
}

resource "digitalocean_droplet" "servers" {
  count = var.server.count

  name = format("%s-server-%d", var.cluster_name, count.index)
  region = var.region
  image = var.server.image
  size = var.server.size
  backups = var.server.backups

  vpc_uuid = digitalocean_vpc.vpc.id

  ssh_keys = [
    digitalocean_ssh_key.server.id,
  ]

  tags = [
    "k3s",
    format("k3s-%s", var.cluster_name),
    format("k3s-%s-server", var.cluster_name),
  ]
}

# waits for ssh to be available on all nodes by doing some preparation
resource "null_resource" "server_ssh_wait" {
  count = var.server.count

  depends_on = [
    digitalocean_droplet.servers
  ]

  connection {
    user = "root"
    host = digitalocean_droplet.servers[count.index].ipv4_address
    private_key = tls_private_key.server.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/rancher/k3s"
    ]
  }
}

resource "null_resource" "server_startup" {
  count = var.server.count

  depends_on = [
    null_resource.server_ssh_wait
  ]

  connection {
    user = "root"
    host = digitalocean_droplet.servers[count.index].ipv4_address
    private_key = tls_private_key.server.private_key_pem
  }

  provisioner "file" {
    destination = "/etc/rancher/k3s/config.yaml"
    content = templatefile("${path.module}/templates/k3s-server.yaml", {
      token = random_string.token.result,
      index = count.index,
      count = var.server.count,
      server = digitalocean_droplet.servers[0].ipv4_address,
      tls_san = digitalocean_loadbalancer.server.ip,
    })
  }

  provisioner "file" {
    destination = "/usr/local/bin/install-k3s.sh"
    content = templatefile("${path.module}/templates/install-k3s.sh", {
      version = var.server.version,
      role = "server"
    })
  }

  provisioner "file" {
    source = "${path.module}/templates/await-k3s.sh"
    destination = "/usr/local/bin/await-k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep ${ count.index * 30 }",
      "bash /usr/local/bin/install-k3s.sh",
      "bash /usr/local/bin/await-k3s.sh",
    ]
  }

  provisioner "local-exec" {
    command = <<EOF
scp \
  -oStrictHostKeyChecking=no \
  -oUserKnownHostsFile=/dev/null \
  -i ${local_file.id_do.filename} \
  root@${digitalocean_droplet.servers[count.index].ipv4_address}:/etc/rancher/k3s/k3s.yaml \
  ${path.module}/kubeconfig-${count.index}.yaml
EOF
  }
}

data "local_file" "kubeconfig" {
  depends_on = [
    null_resource.server_startup,
  ]

  filename = "${path.module}/kubeconfig-0.yaml"
}
