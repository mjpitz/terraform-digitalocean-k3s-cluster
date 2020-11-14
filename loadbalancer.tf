resource "digitalocean_loadbalancer" "server" {
  name = format("%s-api", var.cluster_name)
  region = var.region

  forwarding_rule {
    entry_port = 6443
    entry_protocol = "tcp"
    target_port = 6443
    target_protocol = "tcp"
  }

  healthcheck {
    protocol = "tcp"
    port = 6443
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold = 5
    unhealthy_threshold = 3
  }

  droplet_tag = format("k3s-%s-server", var.cluster_name)

  vpc_uuid = digitalocean_vpc.vpc.id
}
