# ==============================================================================
# User variables

variable "bucket_name" {
  description = "The S3 bucket name to store Terraform state"
}

variable "table_name" {
  description = "The DynamoDB table name to acquire Terraform lock"
}
