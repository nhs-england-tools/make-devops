module "STACK_TEMPLATE_TO_REPLACE" {
  source = "../../modules/rds"

  db_instance = var.db_instance
  db_port     = var.db_port
  db_name     = var.db_name
  db_username = var.db_username

  context            = local.context
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids = [data.terraform_remote_state.security_groups_k8s.outputs.eks_worker_additional_sg_id]
}
