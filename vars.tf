variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "cidrBlock" {
  type = string
}

variable "server" {
  type = object({
    count = number
    image = string
    size = string
    backups = bool
    version = string
  })
}

variable "node_pools" {
  type = list(object({
    count = number
    name = string
    image = string
    size = string
    version = string
  }))
}
