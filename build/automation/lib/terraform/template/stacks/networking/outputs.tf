# ==============================================================================
# Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_id
}
output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_arn
}
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_cidr_block
}
output "vpc_public_subnets" {
  description = "The list of public subnets inside the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_public_subnets
}
output "vpc_private_subnets" {
  description = "The list of private subnets inside the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_private_subnets
}
output "vpc_intra_subnets" {
  description = "The list of internal subnets inside the VPC"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_intra_subnets
}
output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.NAME_TEMPLATE_TO_REPLACE-vpc.default_security_group_id
}

output "route53_zone_zone_id" {
  description = "The zone ID of Route53 zone"
  value       = module.NAME_TEMPLATE_TO_REPLACE-route53.this_route53_zone_zone_id
}
output "route53_zone_name_servers" {
  description = "The name servers of Route53 zone"
  value       = module.NAME_TEMPLATE_TO_REPLACE-route53.this_route53_zone_name_servers
}

output "acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.this_acm_certificate_arn
}
output "acm_certificate_domain_validation_options" {
  description = "A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined. Only set if DNS-validation was used"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.this_acm_certificate_domain_validation_options
}
output "acm_certificate_validation_emails" {
  description = "A list of addresses that received a validation E-Mail. Only set if EMAIL-validation was used"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.this_acm_certificate_validation_emails
}
output "acm_validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.validation_route53_record_fqdns
}
output "acm_distinct_domain_names" {
  description = "List of distinct domains names used for the validation"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.distinct_domain_names
}
output "acm_validation_domains" {
  description = "List of distinct domain validation options. This is useful if subject alternative names contain wildcards"
  value       = module.NAME_TEMPLATE_TO_REPLACE-acm.validation_domains
}
