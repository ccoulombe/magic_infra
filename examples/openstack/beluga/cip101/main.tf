terraform {
  required_version = ">= 0.14.2"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "11.1"

  cluster_name = "cip101"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2020-09"

  instances = {
    mgmt   = { type = "p4-7.5gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p4-7.5gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "c8-60gb", tags = ["node"], count = 1 }
    compute-node =	{ type = "p8-15gb", tags = ["node"], count = 2 }
  }

  volumes = {
    nfs = {
      home     = { size = 20 }
      project  = { size = 20 }
      scratch  = { size = 20 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

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
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
  email            = "YOUR EMAIL"
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.accounts.sudoer.username
}

output "hostnames" {
  value = module.dns.hostnames
}
