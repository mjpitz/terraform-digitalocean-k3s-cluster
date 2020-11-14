resource "digitalocean_vpc" "vpc" {
  name = var.cluster_name
  region = var.region
  ip_range = var.cidrBlock
}
