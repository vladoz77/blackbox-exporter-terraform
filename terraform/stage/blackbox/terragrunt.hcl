# stage/blackbox/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  stage = read_terragrunt_config(find_in_parent_folders("stage.hcl"))
}

terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-instance?ref=main"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    subnet_id = "mock-vpc-subnet_id"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}


inputs = merge(
  local.stage.inputs,
  {
    name = "${local.stage.locals.environment}-blackbox"
    network_interfaces = [
      {
        subnet_id      = dependency.vpc.outputs.subnet_id
        nat            = true
        security_group = []
      }
    ]
    dns_records = {
      "blackbox" = {
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
)