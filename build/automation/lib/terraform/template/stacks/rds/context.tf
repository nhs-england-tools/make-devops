# ==============================================================================
# Context

locals {
  context = {

    aws_account_id   = var.aws_account_id
    aws_account_name = var.aws_account_name
    aws_region       = var.aws_region
    aws_profile      = var.aws_profile

    programme           = var.programme
    project_group       = var.project_group
    project_group_short = var.project_group_short
    project_name        = var.project_name
    project_name_short  = var.project_name_short
    service_tag         = var.service_tag
    project_tag         = var.project_tag
    profile             = var.profile
    environment         = var.profile

    tags = {
      Programme   = var.programme
      Service     = var.service_tag
      Project     = var.project_tag
      Environment = var.profile
    }

  }
}

# ==============================================================================
# Platform variables set by the Make DevOps automation scripts

variable "aws_account_id" {}
variable "aws_account_name" {}
variable "aws_region" {}
variable "aws_profile" {}

# ==============================================================================
# Project variables set by the Make DevOps automation scripts

variable "programme" {}
variable "project_group" {}
variable "project_group_short" {}
variable "project_name" {}
variable "project_name_short" {}
variable "service_tag" {}
variable "project_tag" {}
variable "profile" {}

# ==============================================================================
# Settings

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    encrypt = true
  }
}
