variable "zone" {
  type = string
  description = "yandex zone"
}

variable "network_name" {
  type = string
  description = "network name"
}

variable "subnet_name" {
  type = string
  description = "subnet name"
}

variable "ipv4_cidr" {
  type = list(string)
  description = "cidr ip"
}

