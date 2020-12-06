# ==============================================================================
# Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}
output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}
