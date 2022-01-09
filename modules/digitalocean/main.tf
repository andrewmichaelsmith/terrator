terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

resource "digitalocean_ssh_key" "admin_ssh" {
  name       = "Admin Key"
  public_key = var.public_key_openssh
}

resource "digitalocean_droplet" "tor" {
  ipv6      = true
  size      = "512mb"
  image     = var.os
  name      = var.name
  region    = var.location
  user_data = var.user_data

  ssh_keys = [resource.digitalocean_ssh_key.admin_ssh.fingerprint]
}

output "ipv4" {
  value = resource.digitalocean_droplet.tor.ipv4_address
}