locals {
  environment       = "prod"
  cpu               = 4
  memory            = 4
  core_fraction     = 20
  boot_disk = {
    type = "network-ssd"
    size = 50
  }
  ipv4_cidr    = ["192.168.10.0/24"]
  network_name = "${local.environment}-network"
  subnet_name  = "${local.environment}-subnet"
  static_address = {
    name = "${local.environment}-static-ip"
  }
}

inputs = {
  cpu               = local.cpu
  memory            = local.memory
  core_fraction     = local.core_fraction
  boot_disk         = local.boot_disk
  ipv4_cidr         = local.ipv4_cidr
  network_name      = local.network_name
  subnet_name       = local.subnet_name
  static_address    = local.static_address
}
