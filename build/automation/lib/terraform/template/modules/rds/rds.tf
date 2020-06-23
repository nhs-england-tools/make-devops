module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.16"

  ### DB Instance ##############################################################

  identifier = var.db_instance_identifier
  port       = var.db_port
  name       = var.db_name
  username   = var.db_username
  password   = var.db_password

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  engine                = "postgres"
  engine_version        = "12.2"
  instance_class        = var.db_instance_class
  storage_encrypted     = true

  allow_major_version_upgrade  = false
  apply_immediately            = true
  backup_retention_period      = var.db_backup_retention_period
  backup_window                = "00:00-01:00"
  copy_tags_to_snapshot        = true
  final_snapshot_identifier    = var.db_instance_identifier
  maintenance_window           = "Mon:05:00-Mon:06:00"
  multi_az                     = var.db_multi_az
  performance_insights_enabled = true
  skip_final_snapshot          = var.db_skip_final_snapshot

  vpc_security_group_ids = [var.vpc_security_group]

  ### DB Parameter Group #######################################################

  family = "postgres12"
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

  ### DB Option Group ##########################################################

  major_engine_version = "12"
  options = [
  ]

  ### DB Subnet Group ##########################################################

  subnet_ids = var.private_subnets_ids

  ##############################################################################

  tags = var.tags
}
