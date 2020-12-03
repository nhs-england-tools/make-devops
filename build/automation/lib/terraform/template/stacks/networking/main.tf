module "NAME_TEMPLATE_TO_REPLACE" {
  source = "../../modules/vpc"

  vpc_name = var.vpc_name

  context = local.context
}
