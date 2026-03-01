locals {
  project_name = "investorflow-devops-challenge"
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

# Resource tags
locals {
  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terraform"
  }
}
