# ==============================================================================
# Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE.vpc_id
}
output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE.vpc_arn
}
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE.vpc_cidr_block
}
output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.NAME_TEMPLATE_TO_REPLACE.default_security_group_id
}
