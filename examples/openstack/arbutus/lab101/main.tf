terraform {
  required_version = ">= 1.2.1"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=11.9.7"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "11.9.7"

  cluster_name = "lab101"
  domain       = "calculquebec.cloud"
  image        = "Rocky-8.5-x64-2021-11"

  instances = {
    mgmt   = { type = "p4-7.5gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p4-7.5gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "p2-3gb", tags = ["node"], count = 55 }
  }

  volumes = {
    nfs = {
      home     = { size = 20 }
      project  = { size = 20 }
      scratch  = { size = 20 }
    }
  }

  public_keys = compact(concat(split("\n", file("~/.ssh/id_rsa.pub")), ))

  nb_users = 55
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  hieradata = file("./config.yaml")
}

output "accounts" {
  value = module.openstack.accounts
}

output "public_ip" {
  value = module.openstack.public_ip
}

# Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=11.9.7"
  email            = "YOUR EMAIL"
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.accounts.sudoer.username
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

output "hostnames" {
  value = module.dns.hostnames
}
