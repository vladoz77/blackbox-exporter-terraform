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
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {

  name        = var.instance.name
  platform_id = var.instance.platform_id

  resources {
    cores  = var.instance.cores
    memory = var.instance.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.instance.image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.ssh-access.id, yandex_vpc_security_group.blackbox-exporter-access.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_pub_key}"
  }
}
