terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

resource "aws_security_group" "alb" {
  description = "security group from internet to alb"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_route53_record" "app" {
  count = var.zone_id != "" ? 1 : 0

  zone_id = var.zone_id
  name    = var.app_url
  type    = "A"
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

data "aws_secretsmanager_secret" "app" {
  count = var.okta_enabled ? 1 : 0
  name  = var.secret_name
}
data "aws_secretsmanager_secret_version" "app" {
  count     = var.okta_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.app[count.index].id
}

resource "aws_lb_target_group" "default" {
  name                 = var.default_target_group.name
  port                 = var.default_target_group.port
  protocol             = var.default_target_group.protocol
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path     = var.default_target_group.health_check.path
    port     = var.default_target_group.health_check.port
    protocol = var.default_target_group.health_check.protocol
    matcher  = var.default_target_group.health_check.matcher
  }
  tags = var.default_target_group.tags
}

resource "aws_lb_target_group" "path" {
  for_each             = { for idx, tg in var.path_target_groups : idx => tg }
  name                 = each.value.name
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path     = each.value.health_check.path
    port     = each.value.health_check.port
    protocol = each.value.health_check.protocol
    matcher  = each.value.health_check.matcher
  }
  tags = each.value.tags
}

resource "aws_lb" "app" {
  depends_on         = [aws_security_group.alb]
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [aws_security_group.alb.id]
  tags               = var.tags
  access_logs {
    bucket  = var.log_bucket
    prefix  = "alb-${var.name}"
    enabled = var.log_bucket == "" ? false : true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.app.arn

  dynamic "default_action" {
    for_each = var.okta_enabled ? [1] : []
    content {
      type = "authenticate-oidc"
      authenticate_oidc {
        authorization_endpoint     = "https://login.tx.group/oauth2/v1/authorize"
        client_id                  = jsondecode(data.aws_secretsmanager_secret_version.app[0].secret_string)["okta_client_id"]
        client_secret              = jsondecode(data.aws_secretsmanager_secret_version.app[0].secret_string)["okta_client_secret"]
        issuer                     = jsondecode(data.aws_secretsmanager_secret_version.app[0].secret_string)["okta_login_url"]
        token_endpoint             = "${jsondecode(data.aws_secretsmanager_secret_version.app[0].secret_string)["okta_login_url"]}/oauth2/v1/token"
        user_info_endpoint         = "${jsondecode(data.aws_secretsmanager_secret_version.app[0].secret_string)["okta_login_url"]}/oauth2/v1/userinfo"
        session_cookie_name        = "AWSELBAuthSessionCookie"
        session_timeout            = "3600"
        scope                      = "openid"
        on_unauthenticated_request = "authenticate"
      }
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

resource "aws_lb_listener_rule" "https_listener_rule" {
  for_each     = { for idx, tg in var.path_target_groups : idx => tg }
  listener_arn = aws_lb_listener.https.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.path[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.paths
    }
  }
}

resource "aws_acm_certificate" "app" {
  domain_name       = var.app_url
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_route53_record" "app_ssl_validation" {
  count = var.zone_id != "" ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_type
  zone_id         = var.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "app" {
  count = var.zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [aws_route53_record.app_ssl_validation[0].fqdn]
}
