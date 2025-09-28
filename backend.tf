# Terraform and provider configuration

terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "central-connectivity"
  subscription_id = var.platform.network.subscription_id
}

provider "azurerm" {
  alias           = "global-dns"
  subscription_id = var.platform.dns.subscription_id
}