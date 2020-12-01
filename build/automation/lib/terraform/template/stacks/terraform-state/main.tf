module "NAME_TEMPLATE_TO_REPLACE-store" {
  source = "../../modules/s3"

  bucket_name = var.bucket_name

  context = local.context
}

module "NAME_TEMPLATE_TO_REPLACE-lock" {
  source = "../../modules/dynamodb"

  table_name = var.table_name
  hash_key   = "LockID"
  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  context = local.context
}
