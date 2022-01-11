# terrator

A (work in progress) terraform module to deploy [tor](https://www.torproject.org/) relays to cloud providers.

The goal of this module is to make it quick and easy to create and maintain tor relays on cloud providers using terraform.

Through Terraform, Terrator makes managing tor servers declrative - adding a server to `server_config` will create it, changing a server configuration will replace it and removing it will destroy it.

At present this is an MVP with some limitations, but is being used to run real tor servers.

## Usage

Here's an example minimal viable `main.tf` to run a relay on vultr:

For this example, you will need to create a [vultr](https://www.vultr.com/) account and set `TF_VAR_vultr_api_token=<vultr_api_token>`

```
locals {
  server_config = [
    {
      provider              = "vultr"
      provider_os           = "517"
      provider_location     = "lhr"
      relay_type            = "middle"
      relay_bandwidth_rate  = "5000 KB"
      relay_bandwidth_burst = "10000 KB"
      relay_port            = 9001
      relay_bridge_port     = 9002
    },
  ]
}

module "terrator" {
  source = "git::https://github.com/andrewmichaelsmith/terrator"
  server_config = local.server_config
  tor_contact_info    = "Terrator change me"
  tor_nickname_prefix = "ttor"
  vultr_api_token = var.vultr_api_token
}

variable "vultr_api_token" {
  type        = string
}
```

### Example

With the above as `main.tf`, this will create a tor relay:

```
export TF_VAR_vultr_api_token=<vultr_api_token>
terraform init
terraform apply
```

##  Config

The `server_config` drives the creation of tor servers and their settings, it's a list of `servers`. 

Keys that beging with `provider_` **vary per provider**.

At present, terrator assumes an Ubuntu OS and will almost certainly fail with any other OS.


| Name                  | Description                                                      |
|-----------------------|------------------------------------------------------------------|
| provider              | The cloud provider deploy the server to (see table below)        |
| provider_os           | The OS to deploy (see table below)                               |
| provider_location     | The location to deploy (see table below)                         |
| relay_type            | `middle` or `bridge`                                             |
| relay_bandwidth_rate  | Sets `RelayBandwidthRate` in `torrc`                             |
| relay_bandwidth_burst | Sets `RelayBandwidthBurst` in `torrc`                            |
| relay_port            | Sets `ORPort` in `torrc` and allows firewall                     |
| relay_bridge_port     | If `relay_type` is `bridge`, sets up an obs4 bridge on this port |


### Per provider config

| Name                | `digitialocean`  | `hetzner`  | `vultr`  |
|---------------------|------------------|-----------------------|------------------------------------------|
| `provider_os`       | [link](https://docs.digitalocean.com/reference/api/api-reference/#operation/get_images_list)  (requires API auth)  | [link](https://docs.hetzner.cloud/#images-get-all-images)  (requires API auth) | [link](https://api.vultr.com/v2/os)      |
| `provider_location` | [link](https://docs.digitalocean.com/reference/api/api-reference/#operation/list_all_regions)  (requires API auth) | [link](https://docs.hetzner.com/cloud/general/locations/)                      | [link](https://api.vultr.com/v2/regions) |



## Current Limitations

* No long lived keys - like terraform, we take a [cattle not pets](https://devops.stackexchange.com/questions/653/what-is-the-definition-of-cattle-not-pets) approach to management and have not implemented a master key. Because of this changes to basic configuration will regenerate server keys.
* Basic security - servers will be set to auto update but could likely benefit for additoinal measures.
* Exits untested - these likely need more work.