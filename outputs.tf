# The Omnia platform will use these outputs to integration patterns.
# Terraform outputs

output "storage_account_private_endpoint_fqdn" {
  description = "The FQDN of the Azure Storage Account Private Endpoint."
  value       = azurerm_private_dns_a_record.this.fqdn
}

output "storage_account_id" {
  description = "The ID of the Azure Storage Account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "The name of the Azure Storage Account."
  value       = azurerm_storage_account.this.name
}

output "storage_account_location" {
  description = "The location of the Azure Storage Account."
  value       = azurerm_storage_account.this.location
}