resource "digitalocean_firewall" "private" {
  name = var.cluster_name

  depends_on = [
    null_resource.server_startup,
  ]

  droplet_ids = concat(
    digitalocean_droplet.servers.*.id,
    digitalocean_droplet.agents.*.id,
  )

  inbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    source_addresses = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  inbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    source_addresses = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  inbound_rule {
    protocol = "icmp"
    source_addresses = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }
}

resource "digitalocean_firewall" "public" {
  name = format("%s-public", var.cluster_name)

  depends_on = [
    null_resource.server_startup,
  ]

  droplet_ids = concat(
    digitalocean_droplet.servers.*.id,
    digitalocean_droplet.agents.*.id,
  )

  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
