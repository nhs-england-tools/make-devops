# service-roles

## Description

This stack provisions a number of AWS IAM roles to support a product.

## Usage

### Create an operational stack from the template

    make project-create-profile NAME=tools
    make project-create-infrastructure MODULE_TEMPLATE=iam-roles STACK_TEMPLATE=service-roles PROFILE=tools

### Provision the stack

Depending on the order of execution some of the data sections (except the `terraform-state`) in the `infrastructure/stacks/service-roles/data-texas-v2.tf` file may need to be commented out temporary and restored right after.

    make terraform-plan STACK=service-roles PROFILE=tools
    make terraform-apply-auto-approve STACK=service-roles PROFILE=tools

## Links

- [Creating a role to delegate permissions to an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html)
- [AWS JSON policy elements: Principal](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html)
