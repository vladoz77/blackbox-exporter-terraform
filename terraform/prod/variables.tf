variable "iam_token" {
  type        = string
  description = "Iam token for yandex account"
  sensitive   = true
}

variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
  sensitive   = true
}

variable "folder_id" {
  type        = string
  description = "Yandex folder id"
  sensitive   = true
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "environment" {
  type        = string
  description = "environment for deployment"
}

variable "ssh_pub_key" {
  description = "SSH public key for instance access"
  type        = string
  sensitive   = true
}

variable "username" {
  description = "Username for SSH access"
  type        = string
}

variable "blackbox" {
  description = "blackbox vm config"
  type = object({
    count         = number
    platform_id   = string
    instance_name = string
    cpu           = number
    core_fraction = number
    memory        = number
    boot_disk = object({
      type     = string
      size     = number
      image_id = string
    })
    tags        = optional(list(string))
    environment = optional(map(string))
    dns_records = map(object({
      name = string
      ttl  = number
      type = string
    }))
  })
  default = {
    count         = 1
    platform_id   = "standard-v1"
    instance_name = "monitoring-server"
    cpu           = 1
    core_fraction = 20
    memory        = 2
    tags          = []
    environment   = {}
    boot_disk = {
      type     = "network-hdd"
      size     = 20
      image_id = "fd81hgrcv6lsnkremf32"
    }
    dns_records = {}
  }
}

variable "monitoring" {
  description = "monitoring vm config"
  type = object({
    count         = number
    platform_id   = string
    instance_name = string
    cpu           = number
    core_fraction = number
    memory        = number
    boot_disk = object({
      type     = string
      size     = number
      image_id = string
    })
    tags        = optional(list(string))
    environment = optional(map(string))
    dns_records = map(object({
      name = string
      ttl  = number
      type = string
    }))
  })
  default = {
    count         = 1
    platform_id   = "standard-v1"
    instance_name = "monitoring-server"
    cpu           = 1
    core_fraction = 20
    memory        = 2
    tags          = []
    environment   = {}
    boot_disk = {
      type     = "network-hdd"
      size     = 20
      image_id = "fd81hgrcv6lsnkremf32"
    }
    dns_records = {}
  }
}

variable "network" {
  description = "Network configuration"
  type = object({
    name        = string
    cidr        = string
    subnet_name = string
  })
  default = {
    name        = "blackbox-network"
    cidr        = "10.0.0.0/16"
    subnet_name = "blackbox-subnet"
  }
}
