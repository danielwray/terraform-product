# Main.tf file for Terraform configuration, often left empty or with minimal content.

# Resource Group
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.1.0"

  name     = format("rg-%s-%s-%s", var.environment, var.data_center, var.name)
  location = var.location
  tags     = local.common_tags
}

# Virtual Network with subnets
module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.2.0"

  name                = format("vnet-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/23"]
  tags                = local.common_tags

  subnets = {
    webapp = {
      name             = format("snet-webapp-%s-%s-%s", var.environment, var.data_center, var.name)
      address_prefixes = ["10.0.0.0/26"]
      delegation = [
        {
          name = "webapp-delegation"
          service_delegation = {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    }
    private_endpoints = {
      name             = format("snet-pe-%s-%s-%s", var.environment, var.data_center, var.name)
      address_prefixes = ["10.0.0.64/27"]
    }
    appgw = {
      name             = format("snet-appgw-%s-%s-%s", var.environment, var.data_center, var.name)
      address_prefixes = ["10.0.0.96/27"]
    }
  }
}

# Network Security Group
module "network_security_group" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.2.0"

  name                = format("nsg-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  security_rules = [
    {
      name                       = "AllowHTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.0.0.96/27" # Application Gateway subnet
      destination_address_prefix = "10.0.0.0/26"  # Web App subnet
    },
    {
      name                       = "AllowPostgreSQL"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.0.0.0/26"  # Web App subnet (API)
      destination_address_prefix = "10.0.0.64/27" # Private endpoints subnet
    }
  ]
}

# Associate NSG with webapp subnet
resource "azurerm_subnet_network_security_group_association" "webapp" {
  subnet_id                 = module.virtual_network.subnets["webapp"].resource_id
  network_security_group_id = module.network_security_group.resource_id
}

# Associate NSG with private endpoints subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = module.virtual_network.subnets["private_endpoints"].resource_id
  network_security_group_id = module.network_security_group.resource_id
}

# Service Plan for Linux Web Apps
module "service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "~> 0.2.0"

  name                = format("asp-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  os_type  = "Linux"
  sku_name = "P1v3"
}

# Frontend Web App
module "frontend_webapp" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.10.0"

  name                = format("app-frontend-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  service_plan_id     = module.service_plan.resource_id
  tags                = local.common_tags

  site_config = {
    linux_fx_version = "DOCKER|nginx:latest"
    always_on        = true
    vnet_route_all_enabled = true
  }

  virtual_network_subnet_id = module.virtual_network.subnets["webapp"].resource_id

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
  }
}

# API Web App
module "api_webapp" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.10.0"

  name                = format("app-api-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  service_plan_id     = module.service_plan.resource_id
  tags                = local.common_tags

  site_config = {
    linux_fx_version = "DOCKER|nginx:latest"
    always_on        = true
    vnet_route_all_enabled = true
  }

  virtual_network_subnet_id = module.virtual_network.subnets["webapp"].resource_id

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = format("pip-appgw-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# Application Gateway
module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "~> 0.2.0"

  name                = format("agw-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configurations = [
    {
      name      = "appGatewayIpConfig"
      subnet_id = module.virtual_network.subnets["appgw"].resource_id
    }
  ]

  frontend_ip_configurations = [
    {
      name                 = "appGatewayFrontendIP"
      public_ip_address_id = azurerm_public_ip.appgw.id
    }
  ]

  frontend_ports = [
    {
      name = "port_80"
      port = 80
    },
    {
      name = "port_443"
      port = 443
    }
  ]

  backend_address_pools = [
    {
      name  = "frontend-pool"
      fqdns = [module.frontend_webapp.default_hostname]
    },
    {
      name  = "api-pool"
      fqdns = [module.api_webapp.default_hostname]
    }
  ]

  backend_http_settings = [
    {
      name                  = "frontend-settings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 443
      protocol              = "Https"
      request_timeout       = 60
      pick_host_name_from_backend_address = true
    },
    {
      name                  = "api-settings"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      port                  = 443
      protocol              = "Https"
      request_timeout       = 60
      pick_host_name_from_backend_address = true
    }
  ]

  http_listeners = [
    {
      name                           = "frontend-listener"
      frontend_ip_configuration_name = "appGatewayFrontendIP"
      frontend_port_name             = "port_80"
      protocol                       = "Http"
    }
  ]

  url_path_maps = [
    {
      name                = "path-map"
      default_backend_address_pool_name  = "frontend-pool"
      default_backend_http_settings_name = "frontend-settings"
      path_rules = [
        {
          name                       = "api-rule"
          paths                      = ["/api/*"]
          backend_address_pool_name  = "api-pool"
          backend_http_settings_name = "api-settings"
        }
      ]
    }
  ]

  request_routing_rules = [
    {
      name                       = "routing-rule"
      rule_type                  = "PathBasedRouting"
      http_listener_name         = "frontend-listener"
      url_path_map_name          = "path-map"
      priority                   = 1
    }
  ]
}

# Random password for PostgreSQL
resource "random_password" "postgres_admin" {
  length  = 16
  special = true
}

# PostgreSQL Flexible Server
module "postgresql_flexible_server" {
  source  = "Azure/avm-res-dbforpostgresql-flexibleserver/azurerm?ref=0.2.0"

  name                = format("psql-%s-%s-%s", var.environment, var.data_center, var.name)
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  administrator_login    = "psqladmin"
  administrator_password = random_password.postgres_admin.result

  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 32768
  version    = "14"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = module.virtual_network.subnets["private_endpoints"].resource_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = module.virtual_network.resource_id
  registration_enabled  = false
  tags                  = local.common_tags
}
