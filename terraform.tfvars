cluster_name = "demo"
region = "sfo3"
cidrBlock = "10.64.0.0/16"

server = {
  count = 1
  image = "ubuntu-20-04-x64"
  size = "s-2vcpu-4gb"
  backups = false
  version = "v1.19.3+k3s2"
}

node_pools = [
  {
    count = 3
    name = "primary"
    image = "ubuntu-20-04-x64"
    size = "s-4vcpu-8gb"
    version = "v1.19.3+k3s2"
  }
]
