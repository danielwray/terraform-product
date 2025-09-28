# File contains data lookups for Terraform resources and data sources.
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name     = var.instance.resource_group_name
  location = var.instance.location
}

data "azurerm_subnet" "this" {
  name                 = var.platform.network.subnet_name
  virtual_network_name = var.platform.network.name
  resource_group_name  = data.azurerm_resource_group.this.name
}

data "azurerm_private_dns_zone" "this" {
  name                = var.platform.dns.zone_name
  resource_group_name = var.platform.dns.resource_group_name
}