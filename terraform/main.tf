# modules/vpc will create a VPC with 2 public and 2 private subnets
module "vpc" {
  source = "./modules/vpc"
  cidr = "10.0.0.0/16"
  azs  = ["${var.aws_region}a", "${var.aws_region}b"]
}

# create ECR
resource "aws_ecr_repository" "app" {
  name = "devops-sample-app-${var.environment}"
  image_tag_mutability = "MUTABLE"
}

# IAM role for instances to join ECS
resource "aws_iam_role" "ec2_instance_role" {
  name = "ecs-instance-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy_attach" {
  role = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ecs-instance-profile-${var.environment}"
  role = aws_iam_role.ec2_instance_role.name
}

# ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "devops-cluster-${var.environment}"
}

# ALB
resource "aws_lb" "alb" {
  name               = "devops-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "tg" {
  name     = "devops-tg-${var.environment}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path = "/"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Launch Template for EC2 instances to join ECS cluster
resource "aws_launch_template" "ecs" {
  name_prefix = "ecs-launch-${var.environment}-"
  image_id = data.aws_ami.ecs_ami.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  user_data = base64encode(<<-EOT
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config
  EOT)
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [module.vpc.default_sg_id]
  }
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-asg-${var.environment}"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.public_subnets
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "ecs-instance-${var.environment}"
    propagate_at_launch = true
  }
}

# ECS Task Definition (task will pull the image from ECR)
resource "aws_ecs_task_definition" "task" {
  family                   = "devops-task-${var.environment}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "app"
      image = var.app_image
      essential = true
      portMappings = [
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" }
      ]
      environment = [
        { name = "MONGODB_URI", value = var.mongodb_uri }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = "/ecs/devops-app"
          "awslogs-region" = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/devops-app"
  retention_in_days = 14
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = "devops-service-${var.environment}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}

# Register ASG instances to the target group via instance target (ECS will manage service registration)
# No extra code needed: ECS agent on instances will register tasks to the TG via service.

