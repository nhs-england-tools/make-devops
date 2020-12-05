# service-roles

## Description

This stack provisions a number of AWS IAM roles to support a product.

## Usage

### Create an operational stack from the template

    make project-create-infrastructure MODULE_TEMPLATE=iam-roles STACK_TEMPLATE=service-roles
    make project-create-profile NAME=tools
    cat << HEREDOC >> build/automation/var/profile/tools.mk
    TERRAFORM_NHSD_IDENTITIES_ACCOUNT_ID = 123456789012
    HEREDOC

### Provision the stack

    make terraform-apply-auto-approve STACK=service-roles PROFILE=tools

## Links

- [Creating a role to delegate permissions to an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html)
- [AWS JSON policy elements: Principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html)
