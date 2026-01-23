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
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-network?ref=main"

  zone         = var.zone
  network_name = var.network.name
  subnet_name  = var.network.subnet_name
  ipv4_cidr    = [var.network.cidr]

}

module "monitoring" {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-instance?ref=main"

  count       = var.monitoring.count
  folder_id   = var.folder_id
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
  dns_zone_name     = "home-local-zone"
  dns_records       = var.monitoring.dns_records
}

module "blackbox" {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-instance?ref=main"

  count       = var.blackbox.count
  folder_id   = var.folder_id
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
  dns_zone_name     = "home-local-zone"
  dns_records       = var.blackbox.dns_records
}

module "ansible-inventory" {
  source = "git::https://github.com/vladoz77/terraform-modules.git//ansible-inventory?ref=main"

  environment  = var.environment
  ansible_path = "../../../ansible/inventories"
  groups = {
    blackbox-server   = flatten(module.blackbox[*].public_ips)
    monitoring-server = flatten(module.monitoring[*].public_ips)
  }

  depends_on = [module.blackbox, module.monitoring]
}


