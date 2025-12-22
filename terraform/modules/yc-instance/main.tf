terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.176.0"
    }
  }
  required_version = ">=1.9.8"
}

resource "yandex_compute_disk" "additional_disks" {
  count = length(var.additional_disks)

  name = lower("${var.name}-disk-${count.index}") 
  type = var.additional_disks[count.index].type
  size = var.additional_disks[count.index].size
  zone = var.zone
}

# Instance config
resource "yandex_compute_instance" "instance" {
  name                      = var.name
  labels                    = var.labels
  allow_stopping_for_update = true
  platform_id               = var.platform_id
  zone                      = var.zone

  resources {
    core_fraction       = var.core_fraction
    cores               = var.cores
    memory              = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.boot_disk.image_id
      size     = var.boot_disk.size
      type     = var.boot_disk.type
    }
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.additional_disks[*].id

    content{
      disk_id = secondary_disk.value
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      subnet_id           = network_interface.value.subnet_id
      nat                 = network_interface.value.nat
      ip_address          = network_interface.value.ip_address
      security_group_ids  = network_interface.value.security_group
    }
  }

  metadata = {
    ssh-keys = var.ssh
    tags     = join(",", var.tags)
    user-data = var.cloud_init
  }

  scheduling_policy {
    preemptible = true
  }

  depends_on = [yandex_compute_disk.additional_disks]
}

resource "yandex_dns_recordset" "instance_dns" {
  for_each = var.create_dns_record ? var.dns_records : {}

  zone_id = var.dns_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     =each.value.ttl
  data    = [yandex_compute_instance.instance.network_interface[0].nat_ip_address]

  depends_on = [yandex_compute_instance.instance]
}

# Wait until instance becomes available via SSH
resource "null_resource" "wait_for_ssh" {
  depends_on = [yandex_compute_instance.instance]

  triggers = {
    instance_ip   = yandex_compute_instance.instance.network_interface[0].nat_ip_address
    instance_name = yandex_compute_instance.instance.name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Waiting for SSH on ${yandex_compute_instance.instance.name} (${yandex_compute_instance.instance.network_interface[0].nat_ip_address})..."
      timeout=${var.wait_timeout}
      while [ $timeout -gt 0 ]; do
        # Сначала проверяем доступность порта
        if nc -z -w5 ${yandex_compute_instance.instance.network_interface[0].nat_ip_address} 22 2>/dev/null; then
          echo "SSH порт на ${yandex_compute_instance.instance.name} доступен"
          exit 0
        fi
        echo -n "."
        sleep 5
        timeout=$((timeout - 5))
      done
      echo "Timeout ожидания SSH на ${yandex_compute_instance.instance.name} (${yandex_compute_instance.instance.network_interface[0].nat_ip_address})" >&2
      exit 1
    EOT
  }
}
