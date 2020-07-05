# ==============================================================================
# Outputs

output "db_host" {
  description = "The DB instance host name"
  value       = module.STACK_TEMPLATE_TO_REPLACE.db_host
}

output "db_port" {
  description = "The DB instance port number"
  value       = module.STACK_TEMPLATE_TO_REPLACE.db_port
}

output "db_name" {
  description = "The DB instance schema name"
  value       = module.STACK_TEMPLATE_TO_REPLACE.db_name
}

output "db_username" {
  description = "The DB instance user name"
  value       = module.STACK_TEMPLATE_TO_REPLACE.db_username
}

output "db_password" {
  description = "The DB instance user password location in the AWS Secrets Manager"
  value       = module.STACK_TEMPLATE_TO_REPLACE.db_password
}
