# prod/instance/terragrunt.hcl
include "prod" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-instance?ref=main"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    subnet_id = "mock-vpc-subnet_id"
  }
}



inputs = {
  name          = "monitoring"
  cpu           = 2
  core_fraction = 20
  memory        = 2
  boot_disk = {
    type = "network-hdd"
    size = 20
  }
  network_interfaces = [
    {
      subnet_id      = dependency.vpc.outputs.subnet_id
      nat            = true
      security_group = []
    }
  ]
  tags        = []
  environment = {}
  dns_records = {
    "prometheus" = {
      name = "prometheus"
      type = "A"
      ttl  = 300
    }
    "grafana" = {
      name = "grafana"
      type = "A"
      ttl  = 300
    }
    "alertmanager" = {
      name = "alert"
      type = "A"
      ttl  = 300
    }
    "vmalert" = {
      name = "vmalert"
      type = "A"
      ttl  = 300
    }
  }
}