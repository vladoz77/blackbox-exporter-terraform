# stage/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  stage = read_terragrunt_config(find_in_parent_folders("stage.hcl"))
}

terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-network?ref=main"
}

inputs = local.stage.inputs