# prod/monitoring/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  prod = read_terragrunt_config(find_in_parent_folders("prod.hcl"))
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



inputs = merge(
  local.prod.inputs,
  {
    name = "${local.prod.locals.environment}-monitoring"
    network_interfaces = [
      {
        subnet_id      = dependency.vpc.outputs.subnet_id
        nat            = true
        security_group = []
      }
    ]
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
)