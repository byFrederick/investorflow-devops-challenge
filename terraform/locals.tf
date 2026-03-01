locals {
  project_name = "investorflow"
  environment  = terraform.workspace

  naming_suffix = [
    local.project_name,
    var.azure_location,
    local.environment,
  ]
}

# Network
locals {
  vnet_cidr = {
    dev = "10.10.0.0/16"
    qa  = "10.20.0.0/16"
    stg = "10.30.0.0/16"
    prd = "10.40.0.0/16"
  }

  vnet_subnets = {
    for env, cidr in local.vnet_cidr :
    env => cidrsubnets(cidr, 8)
  }
}

# AKS
locals {
  kubernetes_version = "1.34"

  aks_automatic_channel_upgrade = "patch"
  aks_private_cluster_enabled   = false

  default_node_pool_config = {
    name                        = "default"
    vm_size                     = "Standard_D2s_v3"
    node_count                  = 1
    min_count                   = 1
    max_count                   = 1
    auto_scaling_enabled        = true
    node_taints                 = []
    os_type                     = "Linux"
    temporary_name_for_rotation = "defaulttmp"
  }

  node_pools = {
    general-purpose = merge(local.default_node_pool_config, {
      name                        = "generalp"
      temporary_name_for_rotation = "generalptmp"
      max_count                   = 3
    })
  }

  web_app_routing = {
    dns_zone_ids = []
  }

  aks_attached_acr_id_map = {
    "${local.project_name}" = module.acr.resource_id
  }
}

# Resource tags
locals {
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}
