provider "aws" {
  region                      = "eu-west-2"
  access_key                  = "accesskey"
  secret_key                  = "secretkey"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_force_path_style         = true
  endpoints {
    s3       = "http://${var.localstack_host}:4572"
    dynamodb = "http://${var.localstack_host}:4569"
  }
}
