# Terraform Stack: `ci`

## Description

This stack provisions CI/CD components.

## Dependencies

- `terraform-state` stack
- `service-roles` stack

## Usage

### Create an operational stack from the template

    make project-create-profile NAME=tools
    make project-create-infrastructure MODULE_TEMPLATE=ecr STACK_TEMPLATE=ci PROFILE=tools

### Provision the stack

    make terraform-plan STACK=ci PROFILE=tools
    make terraform-apply-auto-approve STACK=ci PROFILE=tools
