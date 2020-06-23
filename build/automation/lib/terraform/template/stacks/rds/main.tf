module "rds" {
  source                     = "../../modules/rds"
  db_instance_identifier     = var.db_instance
  db_name                    = var.db_name
  db_password                = random_password.NAME_TEMPLATE_TO_REPLACE.result
  db_backup_retention_period = 0
  db_skip_final_snapshot     = true
  vpc_security_group         = aws_security_group.rds_postgres_sg.id
  private_subnets_ids        = data.terraform_remote_state.vpc.outputs.private_subnets
  tags                       = local.tags
}

resource "aws_security_group" "rds_postgres_sg" {
  name   = "${var.db_instance}-db-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  tags   = local.tags
}

resource "aws_security_group_rule" "rds_postgres_ingress_from_eks_worker" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_postgres_sg.id
  source_security_group_id = data.terraform_remote_state.security_groups_k8s.outputs.eks_worker_additional_sg_id
}

resource "aws_secretsmanager_secret" "NAME_TEMPLATE_TO_REPLACE_password" {
  name                    = "${var.db_instance}/deployment"
  recovery_window_in_days = 0
  description             = "Secrets for the DoS Test Database project (${var.db_instance})"
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "NAME_TEMPLATE_TO_REPLACE_password" {
  secret_id     = aws_secretsmanager_secret.NAME_TEMPLATE_TO_REPLACE_password.id
  secret_string = "{\"DB_PASSWORD\": \"${random_password.NAME_TEMPLATE_TO_REPLACE.result}\"}"
}

resource "random_password" "NAME_TEMPLATE_TO_REPLACE" {
  length      = 32
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  special     = false
}
