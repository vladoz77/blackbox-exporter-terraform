terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.176.0"
    }
  }
  required_version = ">=1.9.8"
}

resource "yandex_vpc_network" "network" {
  name = var.network_name 
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.zone  
  v4_cidr_blocks =  var.ipv4_cidr
  network_id     = yandex_vpc_network.network.id  
}

