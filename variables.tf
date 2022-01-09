variable "tor_contact_info" {
  type        = string
  description = "Contact information (Tor ContactInfo)"
}

variable "tor_nickname_prefix" {
  type        = string
  description = "Nickname to prefix relays with"
}

variable "server_config" {
  type = list(object({
    provider              = string
    provider_location     = string
    provider_os           = string
    relay_bandwidth_burst = string
    relay_bandwidth_rate  = string
    relay_port            = number
    relay_bridge_port     = number
    relay_type            = string
  }))
  description = "Configuration for which servers to create"
}

variable "vultr_api_token" {
  type        = string
  description = "Read/Write API token for Vultr"
  default     = ""
}

variable "hetzner_api_token" {
  type        = string
  description = "Read/Write API token for Hetzner"
  default     = "0000000000000000000000000000000000000000000000000000000000000000"
}

variable "digitalocean_api_token" {
  type        = string
  description = "Read/Write API token for DigitalOcean"
  default     = ""
}