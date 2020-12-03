# networking

## Description

## Design

For a sample VPC 10.0.0.0/16
  Public subnets 10.0.192.0/19
    Subnet 10.0.192.0/21, CIDR Address Range: 10.0.192.0-10.0.199.255, Maximum addresses 2043
    Subnet 10.0.200.0/21, CIDR Address Range: 10.0.200.0-10.0.207.255, Maximum addresses 2043
    Subnet 10.0.208.0/21, CIDR Address Range: 10.0.208.0-10.0.215.255, Maximum addresses 2043
  Private subnets 10.0.0.0/17
    Subnet 10.0.0.0/19, CIDR Address Range: 10.0.0.0-10.0.31.255, Maximum addresses 8187
    Subnet 10.0.32.0/19, CIDR Address Range: 10.0.32.0-10.0.63.255, Maximum addresses 8187
    Subnet 10.0.64.0/19, CIDR Address Range: 10.0.64.0-10.0.95.255, Maximum addresses 8187
  Internal subnets 10.0.128.0/18
    Subnet 10.0.128.0/20, CIDR Address Range: 10.0.128.0-10.0.143.255, Maximum addresses 4090
    Subnet 10.0.144.0/20, CIDR Address Range: 10.0.144.0-10.0.159.255, Maximum addresses 4090
    Subnet 10.0.160.0/20, CIDR Address Range: 10.0.160.0-10.0.175.255, Maximum addresses 4090

## Usage

### Create an operational stack from the template

    make project-create-infrastructure MODULE_TEMPLATE=vpc STACK_TEMPLATE=networking
    make project-create-profile NAME=tools
    cat << HEREDOC >> build/automation/var/profile/tools.mk
    TF_VAR_vpc_name = sf.nhs.net
    HEREDOC

### Provision the stack

    make terraform-apply-auto-approve STACK=networking PROFILE=tools
