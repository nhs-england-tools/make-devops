module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.20"
  tags    = var.context.tags

  # DB Instance

  identifier = var.db_instance
  port       = var.db_port
  name       = var.db_name
  username   = var.db_username
  password   = random_password.password.result

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  engine                = "postgres"
  engine_version        = "RDS_POSTGRES_VERSION_TEMPLATE_TO_REPLACE"
  instance_class        = var.db_instance_class
  storage_encrypted     = true

  allow_major_version_upgrade  = false
  apply_immediately            = true
  backup_retention_period      = var.db_backup_retention_period
  backup_window                = "00:00-01:00"
  copy_tags_to_snapshot        = true
  final_snapshot_identifier    = var.db_instance
  maintenance_window           = "Mon:05:00-Mon:06:00"
  multi_az                     = var.db_multi_az
  performance_insights_enabled = true
  skip_final_snapshot          = var.db_skip_final_snapshot

  vpc_security_group_ids = [aws_security_group.security_group.id]

  # DB Parameter Group

  family = "postgres${RDS_POSTGRES_VERSION_MAJOR_TEMPLATE_TO_REPLACE}"
  parameters = [
    {
      name         = "max_connections"
      value        = var.db_max_connections
      apply_method = "pending-reboot"
    },
    {
      name         = "client_encoding"
      value        = "UTF8"
      apply_method = "immediate"
    },
    {
      name         = "ssl"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "timezone"
      value        = "UTC"
      apply_method = "immediate"
    }
  ]

  # DB Option Group

  major_engine_version = "RDS_POSTGRES_VERSION_MAJOR_TEMPLATE_TO_REPLACE"
  options = [
  ]

  # DB Subnet Group

  subnet_ids = var.subnet_ids
}

### Networking #################################################################

resource "aws_security_group" "security_group" {
  name        = "${var.db_instance}-rds-sg"
  vpc_id      = var.vpc_id
  tags        = var.context.tags
  description = "Allow incoming connections to the RDS PostgreSQL instance from a VPC"
}

resource "aws_security_group_rule" "ingress" {
  for_each                 = { for id in var.security_group_ids : id => id }
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security_group.id
  source_security_group_id = each.value
  description              = "Allow incoming connections to the RDS PostgreSQL instance from a Security Group"
}

### Password ###################################################################

resource "aws_secretsmanager_secret" "secret" {
  name                    = "${var.db_instance}/deployment"
  recovery_window_in_days = 0
  description             = "Deployment secrets of the '${var.context.project_group}/${var.context.project_name}' project"
  tags                    = var.context.tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = "{\"DB_PASSWORD\": \"${random_password.password.result}\"}"
}

resource "random_password" "password" {
  length      = 32
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  special     = false
}
