module "NAME_TEMPLATE_TO_REPLACE-vpc" {
  source = "../../modules/vpc"

  vpc_name = var.terraform_networking_vpc_name
  vpc_id   = var.terraform_networking_vpc_id

  context = local.context
}

module "NAME_TEMPLATE_TO_REPLACE-route53" {
  source = "../../modules/route53"

  zone_name = var.terraform_networking_route53_zone_name

  context = local.context
}

module "NAME_TEMPLATE_TO_REPLACE-acm" {
  source = "../../modules/acm"

  cert_domain_name               = var.terraform_networking_route53_zone_name
  cert_subject_alternative_names = ["*.${var.terraform_networking_route53_zone_name}"]
  route53_zone_id                = module.NAME_TEMPLATE_TO_REPLACE-route53.this_route53_zone_zone_id[var.terraform_networking_route53_zone_name]

  context = local.context
}

module "NAME_TEMPLATE_TO_REPLACE-alb" {
  source = "../../modules/alb"

  vpc_id          = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_id
  subnets         = module.NAME_TEMPLATE_TO_REPLACE-vpc.vpc_public_subnets
  security_groups = [module.NAME_TEMPLATE_TO_REPLACE-vpc.default_security_group_id]
  certificate_arn = module.NAME_TEMPLATE_TO_REPLACE-acm.this_acm_certificate_arn

  context = local.context
}
