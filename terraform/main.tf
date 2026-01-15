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
    key    = "instances/blackbox.tfstate"

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

module "blackbox" {
  source = "./modules/yc-instance"

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
      subnet_id = yandex_vpc_subnet.subnet.id
      nat       = true
      security_group = [
        yandex_vpc_security_group.ssh-access.id,
        yandex_vpc_security_group.blackbox-exporter-access.id,
        yandex_vpc_security_group.asme-access.id
      ]
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
    }
  )
  filename   = "../ansible/inventories/${var.environment}/inventory.ini"
  depends_on = [module.blackbox]
}

