# Deploy storage account via module reference

module "my_storage_backend" {
  source = "git::github.com/danielwray/terraform-azurerm-storage-account?ref=v1.0.0"

  region        = local.region
  location      = local.location
  name          = local.name
  environment   = local.environment
  data_center   = local.data_center
  tags          = var.tags
  platform_id   = var.platform_id
  definition_id = var.definition_id
  instance_id   = var.instance_id
  owner         = var.owner
  platform      = var.platform
  instance      = var.instance
}
