variable "platform_id" {
  type = string
  description = "yandex instance platform id"
  default = "standard-v1"
}

variable "zone" {
  type = string
  description = "yandex zone"
  
}

variable "name" {
  type = string
  description = "vm name"
  nullable = true
  default = "yc-instance"
}

variable "core_fraction" {
  type = number
  default = 20
}

variable "cores" {
  type = number
  default = 2
  description = "cpu core for vm"
}

variable "memory" {
  type = number
  default = 2
  description = "memory for vm"
}


variable "ssh" {
  type = string
  description = "ssh key for connect to instance"
  nullable = true
}

variable "tags" {
  type = list(string)
  description = "tags for vm"
  nullable = true
  default = [ ]
}

variable "network_interfaces" {
  type = list(object({
    subnet_id = string
    nat       = bool
    ip_address = optional(string)
    security_group = optional(set(string))
    static_nat_ip_address = optional(string)
  }))
  description = "List of network interfaces for the VM."
  default = [{
    subnet_id = ""
    nat       = true
    ip_address = null
    security_group = null
    static_nat_ip_address = null
  }]
}

variable "boot_disk" {
  type = object({
    image_id = string
    type = string
    size = number
  })
}

variable "additional_disks" {
  nullable = true
  type = list(object({
    size = number
    type = string  # Тип диска (network-hdd, network-ssd, network-ssd-nonreplicated)
  }))
  description = "add additional disk for vm"
  default = [] 
}

variable "labels" {
  type = map(string)
  nullable = true
  default = {}
}

variable "env_vars" {
  type = map(string)
  default = {}
  description = "Env vars to inject to instance"
  nullable = true
}

variable "username" {
  type = string
  default = "ubuntu"
  description = "default user for vm"
}

variable "cloud_init" {
  description = "YAML content for cloud-init configuration"
  type        = string
  default     = null
  sensitive   = false
  nullable = true
}

variable "create_dns_record" {
  type        = bool
  description = "Create DNS record for instance"
  default     = false
}

variable "dns_zone_id" {
  type        = string
  description = "DNS zone ID for record creation"
  default     = ""
}

variable "dns_records" {
  type = map(object({
    name = string
    ttl = number
    type = string
  }))
  default = {}
  description = "dns record config"
}

variable "wait_timeout" {
  description = "Timeout in seconds to wait for instance to become available via SSH"
  type        = number
  default     = 300
}