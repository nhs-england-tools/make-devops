# networking

## Description

This stack provisions RDS PostgreSQL.

## Usage

### Create an operational stack from the template

    make project-create-infrastructure MODULE_TEMPLATE=rds STACK_TEMPLATE=rds STACK=database PROFILE=dev

### Provision the stack

    make terraform-apply-auto-approve STACK=database PROFILE=dev
