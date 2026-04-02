# prod/security-groups/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  prod = read_terragrunt_config(find_in_parent_folders("prod.hcl"))
}

terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-security-groups?ref=security-group-module"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    network_id = "mock-vpc-network_id"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

inputs = merge(
  local.prod.inputs,
  {
    network_id = dependency.vpc.outputs.network_id
    sg_name = "${local.prod.locals.environment}-sg"
    sg_description = "Security group for ${local.prod.locals.environment} environment"
    ingress_rules = {
      "ssh" = {
        protocol       = "TCP"
        port           = 22
        description    = "SSH access"
        v4_cidr_blocks = ["0.0.0.0/0"]
      }
      "http" = {
        protocol       = "TCP"
        port           = 80
        description    = "HTTP access"
        v4_cidr_blocks = ["0.0.0.0/0"]
      }
      "https" = {
        protocol       = "TCP"
        port           = 443
        description    = "HTTPS access"
        v4_cidr_blocks = ["0.0.0.0/0"]  
      }
    }

    egress_rules = {
      "all" = {
        protocol       = "ANY"
        description    = "All egress"
        v4_cidr_blocks = ["0.0.0.0/0"]
        }
    }
  }
)
