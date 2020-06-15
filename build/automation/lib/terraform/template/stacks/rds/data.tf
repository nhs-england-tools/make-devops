data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.terraform_platform_state_store
    key    = var.vpc_terraform_state_key
    region = var.aws_region
  }
}

data "terraform_remote_state" "security_groups_k8s" {
  backend = "s3"
  config = {
    bucket = var.terraform_platform_state_store
    key    = var.security_groups_k8s_terraform_state_key
    region = var.aws_region
  }
}
