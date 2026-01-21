data "yandex_dns_zone" "zone" {
  folder_id = var.folder_id
  name      = "home-local-zone"
}
