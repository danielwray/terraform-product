# locals.tf contains local variables used in multiple areas throughout the Terraform configuration.

resource "random_id" "short_name_unique_id" {
  byte_length = 4
}

resource "random_id" "public_suffix_unique_id" {
  byte_length = 8
}

locals {
  name        = lower(var.name)
  region      = lower(var.region)
  location    = lower(var.location)
  environment = lower(var.environment)
  data_center = lower(var.data_center)

  # Generate unique suffixes for resource names
  name_common_suffix = format("%s-%s", local.data_center, local.name, local.environment)

  # Generate short name suffix for resources with limited character count
  name_short_suffix = format("%s%s%s", local.data_center, substr(local.name, 0, 4), substr(local.environment, 0, 3), random_id.short_name_unique_id.hex)

  # Generate suffix for public resources where we need an obscure identifier
  # This is useful for resources that need to be globally unique, like storage accounts or DNS
  public_suffix = format("%s%s", local.data_center, random_id.public_suffix_unique_id.hex)

  common_tags = merge(
    {
      "Name"         = local.name,
      "Environment"  = local.environment,
      "DataCenter"   = local.data_center,
      "Region"       = local.region,
      "ManagedBy"    = "Terraform",
      "Platform"     = "Omnia",
      "PlatformID"   = try(var.platform_id, "Unknown"),
      "DefinitionID" = try(var.definition_id, "Unknown"),
      "InstanceID"   = try(var.instance_id, "Unknown"),
      "Owner"        = try(var.owner, "Unknown"),
      "SourceURL"    = "https://github.com/omnia/products/my-cool-product",
      "Version"      = var.version
    },
    var.tags,
  )
}