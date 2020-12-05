module "NAME_TEMPLATE_TO_REPLACE" {
  source = "../../modules/vpc"

  vpc_name = var.terraform_networking_vpc_name

  context = local.context
}
