terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
  }
}

resource "vultr_ssh_key" "admin_ssh" {
  name    = "Admin Key"
  ssh_key = var.public_key_openssh
}

resource "vultr_instance" "tor" {
  enable_ipv6 = true
  plan        = "vc2-1c-1gb"
  hostname    = var.name
  os_id       = var.os
  region      = var.location
  user_data   = var.user_data
  ssh_key_ids = [resource.vultr_ssh_key.admin_ssh.id]
}

output "ipv4" {
  value = resource.vultr_instance.tor.main_ip
}
