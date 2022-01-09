terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_ssh_key" "admin_ssh" {
  name       = "Debug SSH key"
  public_key = var.public_key_openssh
}

resource "hcloud_server" "tor" {
  name        = var.name
  server_type = "cx11"
  image       = var.os
  location    = var.location
  user_data   = var.user_data
  ssh_keys    = [hcloud_ssh_key.admin_ssh.name]
}

output "ipv4" {
  value = resource.hcloud_server.tor.ipv4_address
}
