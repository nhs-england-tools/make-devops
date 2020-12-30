# networking

## Description

This stack provisions a Multi-AZ and multi-subnet VPC infrastructure with managed NAT gateways in the public subnet for each Availability Zone.

## Design

![This VPC Architecture](diagram.png)

## Usage

### Create an operational stack from the template

    make project-create-profile NAME=tools
    make project-create-infrastructure MODULE_TEMPLATE=vpc,route53,acm,alb STACK_TEMPLATE=networking PROFILE=tools

### Provision the stack

    make terraform-plan STACK=networking PROFILE=tools
    make terraform-apply-auto-approve STACK=networking PROFILE=tools

### Delegate the domain

Once the stack is created get the list of nameservers from the created hosted zone and add a corresponding DNS record of the NS type in the AWS `live-parent` account in the Texas Platform hosted zone with the NS servers of the created previously hosted zone. This should allow to pass the certificate validation. When this has happened remove the corresponding validation CNAME record.

### TODO

- Document domain and certificate setup
- Document load balancing setup
- Extract web layer to its own stack

## Links

- [VPC Architecture](https://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html)
- [VPCs and subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- [Route53 NS and SOA records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html)
- [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
