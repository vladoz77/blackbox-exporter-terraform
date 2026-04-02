# prod/blackbox/terragrunt.hcl
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
    subnet_id                    = "mock-vpc-subnet_id"
    static_external_ipv4_address = "mock-static_external_ipv4_address"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

inputs = merge(
  local.prod.inputs,
  {
    name   = "${local.prod.locals.environment}-blackbox"
    cpu    = 2
    memory = 2
    network_interfaces = [
      {
        subnet_id      = dependency.vpc.outputs.subnet_id
        nat            = true
        security_group = []
        nat_ip_address = dependency.vpc.outputs.static_external_ipv4_address
      }
    ]
    dns_records = {
      "blackbox" = {
        name = "blackbox"
        type = "A"
        ttl  = 300
      }
    }
  }
)