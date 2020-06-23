# ==============================================================================

variable "db_instance" {}
variable "db_port" {}
variable "db_name" {}
variable "db_username" {}

# ==============================================================================

variable "terraform_platform_state_store" {}
variable "vpc_terraform_state_key" {}
variable "security_groups_k8s_terraform_state_key" {}

variable "aws_account_id" {}
variable "aws_account_name" {}
variable "aws_region" {}
variable "aws_profile" {}

variable "programme" {}
variable "project_group" {}
variable "project_group_short" {}
variable "project_name" {}
variable "project_name_short" {}
variable "service_tag" {}
variable "project_tag" {}

# ==============================================================================

locals {
  tags = {
    Programme = var.programme
    Service   = var.service_tag
    Project   = var.project_tag
  }
}
