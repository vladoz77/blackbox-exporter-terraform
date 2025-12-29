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
