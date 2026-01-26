# stage/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}


terraform {
  source = "git::https://github.com/vladoz77/terraform-modules.git//yc-network?ref=main"
}



inputs = {
  ipv4_cidr    = ["192.168.10.0/24"]
  network_name = "blackbox-network"
  subnet_name  = "blackbox-subnet"
}