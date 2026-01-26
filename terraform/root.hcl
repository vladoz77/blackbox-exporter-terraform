# root.hcl
remote_state {
  backend = "s3"
  config = {
    endpoint                    = "https://storage.yandexcloud.net"
    bucket                      = "vladis-terraform-state"
    region                      = "${local.folder_id}"
    key                         = "instances/${path_relative_to_include()}/blackbox.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

locals {
  zone              = "ru-central1-a"
  ssh_pub_key       = get_env("TF_VAR_ssh_pub_key", "")
  iam_token         = get_env("TF_VAR_iam_token", "")
  cloud_id          = get_env("TF_VAR_cloud_id", "")
  folder_id         = get_env("TF_VAR_folder_id", "")
  access_key        = get_env("ACCESS_KEY", "")
  secret_key        = get_env("SECRET_KEY", "")
  os_name           = "ubuntu-2404-lts"
  dns_zone_name     = "home-local-zone"
  create_dns_record = true
  platform_id       = "standard-v1"
  username          = "ubuntu"
}

inputs = {
  zone              = local.zone
  folder_id         = local.folder_id
  cloud_id          = local.cloud_id
  iam_token         = local.iam_token
  ssh               = "${local.username}:${local.ssh_pub_key}"
  os_name           = local.os_name
  dns_zone_name     = local.dns_zone_name
  create_dns_record = local.create_dns_record
  platform_id       = local.platform_id
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {}
    }
  EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    provider "yandex" {
      token     = "${local.iam_token}"
      cloud_id  = "${local.cloud_id}"
      folder_id = "${local.folder_id}"
      zone      = "${local.zone}"
    }
    EOF
}



