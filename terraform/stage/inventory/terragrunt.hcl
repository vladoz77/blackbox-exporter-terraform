# stage/inventory/terragrunt.hcl
terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//ansible-inventory?ref=main"
}

dependency "blackbox" {
  config_path = "../blackbox"
  mock_outputs = {
    public_ips = ["10.0.0.1"]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate", "init"]
}

locals {
  environment = "stage"
}

inputs = {
  environment  = local.environment
  ansible_path = "${get_repo_root()}/ansible/inventories"
  groups = {
    monitoring-blackbox-server = dependency.blackbox.outputs.public_ips
  }
}