# networking

## Description

This stack provisions a Multi-AZ and multi-subnet VPC infrastructure with managed NAT gateways in the public subnet for each Availability Zone.

## Design

![This VPC Architecture](diagram.png)

## Usage

### Create an operational stack from the template

    make project-create-infrastructure MODULE_TEMPLATE=vpc STACK_TEMPLATE=networking
    make project-create-profile NAME=tools
    cat << HEREDOC >> build/automation/var/profile/tools.mk
    TERRAFORM_NETWORKING_VPC_NAME = \$(PROJECT_ID)-\$(AWS_ACCOUNT_NAME)
    HEREDOC

### Provision the stack

    make terraform-apply-auto-approve STACK=networking PROFILE=tools

## Links

- [VPC Architecture](https://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html)
- [VPCs and subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
