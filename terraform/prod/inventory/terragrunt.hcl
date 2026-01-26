# prod/inventory/terragrunt.hcl
terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//ansible-inventory?ref=main"
}

dependency "monitoring" {
  config_path = "../monitoring"
  mock_outputs = {
    public_ips = [""]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

dependency "blackbox" {
  config_path = "../blackbox"
  mock_outputs = {
    public_ips = [""]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

locals {
  environment = "prod"
}

inputs = {
  environment  = local.environment
  ansible_path = "${get_repo_root()}/ansible/inventories"
  groups = {
    blackbox-server   = dependency.blackbox.outputs.public_ips
    monitoring-server = dependency.monitoring.outputs.public_ips
  }
}