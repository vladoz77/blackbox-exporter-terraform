terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.176.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "vladis-terraform-state"
    region = "ru-central1"
    key    = "instances/prod/blackbox.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_version = ">=1.9.8"
}

provider "yandex" {
  token     = var.iam_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

module "network" {
  source = "../../modules/yc-network"

  zone         = var.zone
  network_name = var.network.name
  subnet_name  = var.network.subnet_name
  ipv4_cidr    = [var.network.cidr]

}

module "monitoring" {
  source = "../../modules/yc-instance"

  count       = var.monitoring.count
  name        = "monitoring-${count.index + 1}"
  zone        = var.zone
  platform_id = var.monitoring.platform_id
  cores       = var.monitoring.cpu
  memory      = var.monitoring.memory
  ssh         = "${var.username}:${var.ssh_pub_key}"
  boot_disk   = var.monitoring.boot_disk
  network_interfaces = [
    {
      subnet_id      = module.network.subnet_id
      nat            = true
      security_group = []
    }
  ]
  create_dns_record = true
  dns_zone_id       = data.yandex_dns_zone.zone.id
  dns_records       = var.monitoring.dns_records
}

module "blackbox" {
  source = "../../modules/yc-instance"

  count       = var.blackbox.count
  name        = "blackbox-${count.index + 1}"
  zone        = var.zone
  platform_id = var.blackbox.platform_id
  cores       = var.blackbox.cpu
  memory      = var.blackbox.memory
  ssh         = "${var.username}:${var.ssh_pub_key}"
  boot_disk   = var.blackbox.boot_disk
  network_interfaces = [
    {
      subnet_id      = module.network.subnet_id
      nat            = true
      security_group = []
    }
  ]
  create_dns_record = true
  dns_zone_id       = data.yandex_dns_zone.zone.id
  dns_records       = var.blackbox.dns_records
}



resource "local_file" "inventory" {
  content = templatefile("./inventory.tftpl",
    {
      blackbox   = flatten(module.blackbox[*].public_ips)
      monitoring = flatten(module.monitoring[*].public_ips)
    }
  )
  filename   = "../../../ansible/inventories/${var.environment}/inventory.ini"
  depends_on = [module.blackbox]
}

output "blackbox_public_ip" {
  value = try(module.blackbox[*].public_ips, [])
}

output "blackbox_fqdn" {
  description = "Full FQDN of instances managed by blackbox module"
  value = flatten([
    for instance in module.blackbox : [
      for name in instance.fqdn : [
        "${name}.${data.yandex_dns_zone.zone.zone}"
      ]
    ]
  ])
}

output "monitoring_public_ip" {
  value = try(module.monitoring[*].public_ips, [])
}

output "monitoring_fqdn" {
  description = "Full FQDN of instances managed by mointoring module"
  value = flatten([
    for instance in module.monitoring : [
      for name in instance.fqdn : [
        "${name}.${data.yandex_dns_zone.zone.zone}"
      ]
    ]
  ])
}