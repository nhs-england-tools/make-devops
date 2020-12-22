# ==============================================================================
# Data

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    key    = "${var.terraform_state_key_shared_infra}/networking/terraform.state"
    bucket = var.terraform_state_store_shared_infra
    region = var.aws_region
  }
}
data "terraform_remote_state" "service-roles" {
  backend = "s3"
  config = {
    key    = "${var.terraform_state_key_shared_infra}/service-roles/terraform.state"
    bucket = var.terraform_state_store_shared_infra
    region = var.aws_region
  }
}
data "terraform_remote_state" "terraform-state" {
  backend = "s3"
  config = {
    key    = "${var.terraform_state_key_shared_infra}/terraform-state/terraform.state"
    bucket = var.terraform_state_store_shared_infra
    region = var.aws_region
  }
}

# ==============================================================================
# Terraform state keys and store set by the Make DevOps automation scripts

variable "terraform_state_store_shared_infra" {}
variable "terraform_state_key_shared_infra" {}
