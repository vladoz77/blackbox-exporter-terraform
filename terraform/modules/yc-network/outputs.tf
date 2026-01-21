output "network_id" {
  value = yandex_vpc_network.network.id
  description = "Get network_id from our network"
}

output "subnet_id" {
  value = yandex_vpc_subnet.subnet.id
  description = "Get subnet_id from our network"
}


output "network_cidr" {
  value = yandex_vpc_subnet.subnet.v4_cidr_blocks[0]
}