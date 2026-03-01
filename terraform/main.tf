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

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "~> 11.1.0"

  prefix              = module.naming.kubernetes_cluster.name
  cluster_name        = module.naming.kubernetes_cluster.name
  sku_tier            = "Standard"
  kubernetes_version  = local.kubernetes_version
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.main.name

  automatic_channel_upgrade       = local.aks_automatic_channel_upgrade
  image_cleaner_enabled           = true
  log_analytics_workspace_enabled = false

  role_based_access_control_enabled = true
  rbac_aad_azure_rbac_enabled       = false
  rbac_aad_admin_group_object_ids   = [data.azuread_group.aks-admins.object_id]

  oidc_issuer_enabled = true

  private_cluster_enabled = local.aks_private_cluster_enabled
  network_plugin          = "azure"
  network_plugin_mode     = "overlay"
  load_balancer_sku       = "standard"

  agents_pool_name             = local.default_node_pool_config.name
  temporary_name_for_rotation  = local.default_node_pool_config.temporary_name_for_rotation
  agents_size                  = local.default_node_pool_config.vm_size
  agents_count                 = local.default_node_pool_config.node_count
  agents_min_count             = local.default_node_pool_config.min_count
  agents_max_count             = local.default_node_pool_config.max_count
  auto_scaling_enabled         = local.default_node_pool_config.auto_scaling_enabled
  only_critical_addons_enabled = true
  vnet_subnet                  = local.default_node_pool_config.vnet_subnet

  node_pools          = local.node_pools
  web_app_routing     = local.web_app_routing
  attached_acr_id_map = local.aks_attached_acr_id_map

  depends_on = [
    azurerm_resource_group.main
  ]

  tags = local.tags
}
