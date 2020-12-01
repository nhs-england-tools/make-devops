# terraform-state

## Description

The purpose of this stack is to provision S3 bucket and DynamoDB table to store the Terraform state of the corresponding infrastructure.

## Usage

### Create an operational stack from the template

    make project-create-infrastructure MODULE_TEMPLATE=s3,dynamodb STACK_TEMPLATE=terraform-state
    make project-create-profile NAME=pipeline
    cat << HEREDOC >> build/automation/var/profile/pipeline.mk
    TF_VAR_bucket_name = \$(TERRAFORM_STATE_STORE)
    TF_VAR_table_name = \$(TERRAFORM_STATE_LOCK)
    HEREDOC

### Provision the stack

Firstly, the content of the `terraform.tf` file has to be commented out as the S3 bucket to store the state has not yet been created.

    make terraform-apply-auto-approve STACK=terraform-state TERRAFORM_USE_STATE_STORE=false PROFILE=pipeline

### Store its own state

Now, having created the S3 bucket to store the state and DynamoDB table to acquire the lock, it is time to upload the local state. Therefore, restore the content of the `terraform.tf` file back to what it was originally prior to executing the following command.

    make terraform-apply-auto-approve STACK=terraform-state TERRAFORM_DO_NOT_REMOVE_STATE_FILE=true PROFILE=pipeline
