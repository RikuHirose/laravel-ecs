locals {
  # セキュリティグループの名前
  sg_name  = "${var.name}-alb-sg"
  alb_name = "${var.name}-alb"
}

resource "aws_security_group" "this" {
  name        = local.sg_name
  description = local.sg_name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.sg_name
  }
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "this" {
  load_balancer_type = "application"
  name               = local.alb_name

  security_groups = [aws_security_group.this.id]
  subnets         = var.public_subnet_ids
}

resource "aws_lb_listener" "http" {
  port     = "80"
  protocol = "HTTP"

  load_balancer_arn = aws_lb.this.arn

  lifecycle {
    create_before_destroy = true
  }

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
  port     = "443"
  protocol = "HTTPS"

  certificate_arn   = var.acm_id
  load_balancer_arn = aws_lb.this.arn

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

# data "aws_route53_zone" "this" {
#   name         = var.domain
#   private_zone = false
# }

# resource "aws_route53_record" "this" {
#   type = "A"

#   name    = var.origin_domain
#   zone_id = data.aws_route53_zone.this.id

#   alias {
#     name                   = aws_lb.this.dns_name
#     zone_id                = aws_lb.this.zone_id
#     evaluate_target_health = false
#   }
# }

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "alb_security_group_id" {
  value = aws_security_group.this.id
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
