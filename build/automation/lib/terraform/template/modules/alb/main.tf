module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"
  tags    = var.context.tags

  name                        = "front-lb"
  load_balancer_type          = "application"
  listener_ssl_policy_default = "ELBSecurityPolicy-TLS-1-2-2017-01"

  vpc_id          = var.vpc_id
  subnets         = var.subnets
  security_groups = var.security_groups

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = var.certificate_arn
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
  target_groups = [
    {
      name             = "cluster"
      backend_protocol = "HTTPS"
      backend_port     = 443
      target_type      = "ip"
    }
  ]
  target_group_tags = var.context.tags
}
