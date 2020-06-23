variable "db_instance_identifier" {}
variable "db_port" { default = 5432 }
variable "db_name" { default = "postgres" }
variable "db_username" { default = "postgres" }
variable "db_password" { default = "postgres" }
variable "db_max_connections" { default = 100 }

variable "db_instance_class" { default = "db.t3.micro" }
variable "db_allocated_storage" { default = 5 }
variable "db_max_allocated_storage" { default = 50 }
variable "db_backup_retention_period" { default = 7 }
variable "db_multi_az" { default = false }
variable "db_skip_final_snapshot" { default = false }

variable "vpc_security_group" {}
variable "private_subnets_ids" {}

variable "tags" {}
