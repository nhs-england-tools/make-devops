# ==============================================================================
# Mandatory variables

variable "vpc_id" { description = "VPC id where the load balancer and other resources will be deployed" }
variable "subnets" { description = "A list of subnets to associate with the load balancer" }
variable "security_groups" { description = "The security groups to attach to the load balancer" }
variable "certificate_arn" { description = "ARN of the SSL certificate to apply to the HTTPS listener" }

# ==============================================================================
# Context

variable "context" { description = "A set of predefined variables coming from the Make DevOps automation scripts and shared by the means of the context.tf file in each individual stack" }
