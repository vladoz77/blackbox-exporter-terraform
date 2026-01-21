resource "yandex_vpc_security_group" "ssh-access" {
  name        = "ssh-access"
  network_id  = module.network.network_id
  description = "Ingress rules for SSH access"

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "accept all trafic to 22 port"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "accept any egress trafic from any address"
  }
}

resource "yandex_vpc_security_group" "blackbox-exporter-access" {
  name        = "blackbox-exporter-access"
  network_id  = module.network.network_id
  description = "Ingress rules for accses to blackbox-exporter port"

  ingress {
    protocol       = "TCP"
    port           = 9115
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "accept all trafic to 9115 port"
  }
}

resource "yandex_vpc_security_group" "asme-access" {
  name        = "asme-access"
  network_id  = module.network.network_id
  description = "Ingress rules for Traefik (HTTP/HTTPS and ACME challenge)"

  ingress {
    protocol       = "TCP"
    description    = "HTTP for ACME challenge and web traffic"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}