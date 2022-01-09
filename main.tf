terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.16.0"
    }
    vultr = {
      source  = "vultr/vultr"
      version = "2.7.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.32.2"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_api_token
}
provider "vultr" {
  api_key     = var.vultr_api_token
  rate_limit  = 700
  retry_limit = 3
}

provider "digitalocean" {
  token = var.digitalocean_api_token
}

locals {
  servers = {
    for i, s in zipmap(range(length(var.server_config)), var.server_config) :
    "tor${i}" => {
      "provider" : s.provider,
      "provider_os" : s.provider_os,
      "provider_location" : s.provider_location,
      "relay_type" : s.relay_type,
      "user_data" : templatefile("${path.module}/cloud-config.yaml",
        {
          "operator_contact_info" : var.tor_contact_info,
          "relay_type" : s.relay_type,
          "relay_port" : s.relay_port,
          "relay_bridge_port" : s.relay_bridge_port,
          "relay_bandwidth_rate" : s.relay_bandwidth_rate,
          "relay_bandwidth_burst" : s.relay_bandwidth_burst,
          "relay_nickname" : "${var.tor_nickname_prefix}${i}",
          "tor_config" : indent(4, file("${path.module}/tor-config.sh")),
          "update_tor_config" : indent(4, file("${path.module}/update-tor-config.sh")),
    }) }
  }



  servers_hetzner = {
    for name, s in local.servers : name => s if s.provider == "hetzner"
  }

  servers_vultr = {
    for name, s in local.servers : name => s if s.provider == "vultr"
  }

  servers_digitalocean = {
    for name, s in local.servers : name => s if s.provider == "digitalocean"
  }

}

# TODO SECURITY XXX This key will live in the state file
resource "tls_private_key" "ssh_key" {
  for_each    = { for name, s in local.servers : name => s }
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
module "vultr" {
  for_each           = { for name, s in local.servers_vultr : name => s }
  source             = "./modules/vultr"
  os                 = each.value.provider_os
  name               = each.key
  location           = each.value.provider_location
  user_data          = each.value.user_data
  public_key_openssh = tls_private_key.ssh_key[each.key].public_key_openssh
}

module "hetzner" {
  for_each           = { for name, s in local.servers_hetzner : name => s }
  source             = "./modules/hetzner"
  os                 = each.value.provider_os
  name               = each.key
  location           = each.value.provider_location
  user_data          = each.value.user_data
  public_key_openssh = tls_private_key.ssh_key[each.key].public_key_openssh
}

module "digitalocean" {
  for_each           = { for name, s in local.servers_digitalocean : name => s }
  source             = "./modules/digitalocean"
  os                 = each.value.provider_os
  name               = each.key
  location           = each.value.provider_location
  user_data          = each.value.user_data
  public_key_openssh = tls_private_key.ssh_key[each.key].public_key_openssh
}

locals {

  do = { for name, s in module.digitalocean : name => s.ipv4 }
  he = { for name, s in module.hetzner : name => s.ipv4 }
  vu = { for name, s in module.vultr : name => s.ipv4 }

  ipv4_map = merge(
    local.do,
    local.he,
    local.vu
  )

  # Remove bridges from ipv4 map
  family_map = { for k, v in local.ipv4_map : k => v if local.servers[k].relay_type != "bridge" }
}

# Write IPs of other relays in to a file (/root/known_ips) that update-tor-config.sh uses later
#
# I don't really like this approach but it does mean servers generate their keys
# and terraform doesn't know them.
resource "null_resource" "set_family_ip" {

  for_each = local.family_map

  triggers = {
    ip4 = "%{for k, v in local.family_map}${v} %{endfor}"
  }

  connection {
    type        = "ssh"
    host        = local.family_map[each.key]
    user        = "root"
    private_key = tls_private_key.ssh_key[each.key].private_key_pem
    timeout     = "20m"
  }

  provisioner "remote-exec" {
    # TODO SECURITY Does not need to be a root user
    inline = [
      for k, v in local.family_map : "echo ${v} >> /root/known_ips"
    ]
  }
}
