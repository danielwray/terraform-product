# The Omnia platform will use these inputs to integration patterns.

## Core Variables
# These variables are populated by the Omnia Platform.
variable "region" {
  description = "Business region."
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "name" {
  description = "Name of the resource."
  type        = string
}

variable "environment" {
  description = "Environment of the resource."
  type        = string
}

variable "data_center" {
  description = "Data center of the resource."
  type        = string
}

variable "tags" {
  description = "Tags for the resource."
  type        = map(string)
}

## Omnia Platform Variables
# These variables are populated by the Omnia Platform.
variable "platform_id" {
  description = "Platform ID."
  type        = string
}

variable "definition_id" {
  description = "Definition ID."
  type        = string
}

variable "instance_id" {
  description = "Instance ID."
  type        = string
}

variable "owner" {
  description = "Owner of the resource."
  type        = string
}

variable "source_url" {
  description = "Source URL of the resource."
  type        = string
}

variable "platform" {
  description = "Platform configuration, specification set by Omnia Platform."
  type = object({
    tier = object({
      high_performance_required  = bool
      disaster_recovery_required = bool
      high_availability_required = bool
      data_encryption_required   = bool
      data_retention_required    = bool
      pci_dss_required           = bool
    })
    dns = object({
      subscription_id     = string
      zone_name           = string
      resource_group_name = string
    })
    network = object({
      subscription_id = string
      name            = string
      subnet_name     = string
    })
  })
}

variable "instance" {
  description = "Instance configuration, specification set by Omnia Platform."
  type = object({
    resource_group_name = string
    location            = string
  })
}

## Terraform Variables
## Specific variables for Terraform resources.
variable "version" {
  description = "Version of the product."
  type        = string
}