locals {
  kubeconfig = yamldecode(data.local_file.kubeconfig.content)
  host = "${digitalocean_loadbalancer.server.ip}:6443"

  cluster_ca_certificate = local.kubeconfig.clusters[0].cluster.certificate-authority-data
  client_key = local.kubeconfig.users[0].user.client-key-data
  client_certificate = local.kubeconfig.users[0].user.client-certificate-data
}

output "endpoint" {
  value = "https://${local.host}"
}

output "kube_config" {
  value = [{
    host = local.host,
    cluster_ca_certificate = local.cluster_ca_certificate,
    client_key = local.client_key,
    client_certificate = local.client_certificate,
    raw_config = <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${local.cluster_ca_certificate}
    server: https://${local.host}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: admin
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: admin
  user:
    client-certificate-data: ${local.client_certificate}
    client-key-data: ${local.client_key}
EOF
  }]
}
