resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}


#################################
##    ALB Resources   ##
#################################

data "aws_subnet_ids" "this" {
  vpc_id = var.vpc_id

  tags = {
    Tier = "Public"
  }
}

resource "aws_lb" "this" {
  name               = "basic-load-balancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.this.ids

  enable_cross_zone_load_balancing = true
}



#################################
##    ALB Listners             ##
#################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn

  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

data "aws_acm_certificate" "this" {
  domain = "${var.dns_record_name}.${var.dns_zone_name}"
}



#################################
##    ALB Target Groups        ##
#################################

resource "aws_lb_target_group" "this" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  depends_on = [aws_lb.this]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "target" {
  autoscaling_group_name = var.autoscaling_group_name
  alb_target_group_arn   = aws_lb_target_group.this.arn
}


resource "aws_lb_listener_rule" "redirect_based_on_path" {
  listener_arn = aws_lb_listener.this.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["/version/*"]
    }
  }
}



##################################
##    Security Group Resources  ##
##################################

resource "aws_security_group" "this" {
  description = "Allow connection between ALB and target"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.ports

  security_group_id = aws_security_group.this.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}



###############################
##    Route53 Resources      ##
###############################

data "aws_route53_zone" "this" {
  name = var.dns_zone_name
}

resource "aws_route53_record" "this" {
  name = var.dns_record_name
  type = "CNAME"

  records = [
    aws_lb.this.dns_name,
  ]

  zone_id = data.aws_route53_zone.this.zone_id
  ttl     = "60"
}

resource "aws_acm_certificate" "finlex_certificate" {
  domain_name       = "${var.dns_record_name}.${var.dns_zone_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "finlex_certificate_validation" {
  certificate_arn         = aws_acm_certificate.finlex_certificate.arn
  validation_record_fqdns = [aws_route53_record.web_cert_validation.fqdn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web_cert_validation" {
  name = aws_acm_certificate.finlex_certificate.domain_validation_options.0.resource_record_name
  type = aws_acm_certificate.finlex_certificate.domain_validation_options.0.resource_record_type

  records = [aws_acm_certificate.finlex_certificate.domain_validation_options.0.resource_record_value]

  zone_id = data.aws_route53_zone.zone.id
  ttl     = 60

  lifecycle {
    create_before_destroy = true
  }
}



###############################
##    ECS TaskDef Resources  ##
###############################

resource "aws_ecs_task_definition" "primary" {
  container_definitions    = <<TASK_DEFINITION
		[
			{
			"name": var.imageName,
			"image": var.imageNameUrl,
			"cpu": 1024,
			"memory": 2048,
			"essential": true
			}
		]
TASK_DEFINITION

  family                   = local.long_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

  lifecycle {
      create_before_destroy = true
    }
  tags = var.tags
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



###############################
##    ECS Service Resources  ##
###############################

resource "aws_ecs_service" "service" {
  depends_on = [aws_lb_target_group.this]

  name                               = var.srvc_name
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.primary.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"

  network_configuration {
    subnets         = local.subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }


