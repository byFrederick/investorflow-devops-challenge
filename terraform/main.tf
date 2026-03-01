module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.3"

  suffix = local.naming_suffix
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group.name
  location = var.azure_location
  tags     = local.tags
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "~> 0.2.1"

  name                = module.naming.nat_gateway.name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.main.name

  sku_name = "Standard"

  public_ips = {
    primary = {
      name = module.naming.public_ip.name
    }
  }

  public_ip_configuration = {
    sku = "Standard"
  }

  tags = local.tags
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17.0"

  name      = module.naming.virtual_network.name
  location  = var.azure_location
  parent_id = azurerm_resource_group.main.id

  address_space = [
    local.vnet_cidr[local.environment]
  ]

  subnets = {
    aks = {
      name                            = module.naming.subnet.name
      address_prefix                  = local.vnet_subnets[local.environment][0]
      default_outbound_access_enabled = false
      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
    }
  }

  tags = local.tags
}

module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "~> 0.5.0"

  name                = replace(module.naming.container_registry.name, "-", "")
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.main.name

  sku = "Standard"

  zone_redundancy_enabled = false

  tags = local.tags
}
