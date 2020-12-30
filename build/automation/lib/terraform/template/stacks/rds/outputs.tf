# ==============================================================================
# Outputs

output "db_host" {
  description = "The DB instance host name"
  value       = module.NAME_TEMPLATE_TO_REPLACE-rds.db_host
}

output "db_port" {
  description = "The DB instance port number"
  value       = module.NAME_TEMPLATE_TO_REPLACE-rds.db_port
}

output "db_name" {
  description = "The DB instance schema name"
  value       = module.NAME_TEMPLATE_TO_REPLACE-rds.db_name
}

output "db_username" {
  description = "The DB instance username"
  value       = module.NAME_TEMPLATE_TO_REPLACE-rds.db_username
}

output "db_password" {
  description = "The DB instance password"
  value       = module.NAME_TEMPLATE_TO_REPLACE-rds.db_password
}
