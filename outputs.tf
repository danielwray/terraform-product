# The Omnia platform will use these outputs to integration patterns.
# Terraform outputs

output "resource_group_name" {
  description = "The name of the resource group."
  value       = module.resource_group.name
}

output "virtual_network_id" {
  description = "The ID of the virtual network."
  value       = module.virtual_network.resource_id
}

output "application_gateway_public_ip" {
  description = "The public IP address of the Application Gateway."
  value       = azurerm_public_ip.appgw.ip_address
}

output "frontend_webapp_hostname" {
  description = "The hostname of the frontend web app."
  value       = module.frontend_webapp.default_hostname
}

output "api_webapp_hostname" {
  description = "The hostname of the API web app."
  value       = module.api_webapp.default_hostname
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server."
  value       = module.postgresql_flexible_server.fqdn
}

output "postgresql_admin_username" {
  description = "The administrator username for PostgreSQL."
  value       = module.postgresql_flexible_server.administrator_login
  sensitive   = true
}

output "postgresql_admin_password" {
  description = "The administrator password for PostgreSQL."
  value       = random_password.postgres_admin.result
  sensitive   = true
}