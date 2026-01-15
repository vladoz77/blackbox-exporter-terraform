username = "ubuntu"
zone     = "ru-central1-a"
environment = "stage"

blackbox = {
  count         = 1
  platform_id   = "standard-v1"
  instance_name = "blackbox"
  cpu           = 2
  core_fraction = 20
  memory        = 2
  boot_disk = {
    type     = "network-hdd"
    size     = 20
    image_id = "fd84r9t01ao2ktahik80"
  }
  tags        = []
  environment = {}
  dns_records = {
    "blackbox-exporter" = {
      name = "blackbox"
      type = "A"
      ttl  = 300
    }
    "prometheus" = {
      name = "prometheus"
      type = "A"
      ttl  = 300
    }
  }
}

network = {
  cidr        = "192.168.10.0/24"
  name        = "blackbox-network"
  subnet_name = "blackbox-subnet"
}
