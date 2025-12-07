# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-bluegreen-vpc"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecs-bluegreen-igw"
  }
}

# -----------------------------
# Public Subnets
# -----------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# -----------------------------
# Route Table
# -----------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Attach subnets to route table
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# -----------------------------------
# Security Group for ALB
# -----------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# -----------------------------------
# Security Group for ECS Tasks
# -----------------------------------
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-security-group"
  }
}

# -----------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------
resource "aws_lb" "alb" {
  name               = "ecs-bluegreen-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "ecs-bluegreen-alb"
  }
}

# -----------------------------------
# ALB Listener (HTTP Port 80)
# -----------------------------------

locals {
  active_tg_arn = var.active_color == "green" ? aws_lb_target_group.green_tg.arn : aws_lb_target_group.blue_tg.arn
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn =local.active_tg_arn
  }
}

# -----------------------------------
# Blue Target Group
# -----------------------------------
resource "aws_lb_target_group" "blue_tg" {
  name        = "blue-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200" 
  }

  tags = {
    Name = "blue-target-group"
  }
}

# -----------------------------------
# Green Target Group
# -----------------------------------
resource "aws_lb_target_group" "green_tg" {
  name        = "green-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200" 
  }

  tags = {
    Name = "green-target-group"
  }
}

# Rule for green target group
resource "aws_lb_listener_rule" "green_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green_tg.arn
  }

  condition {
    path_pattern {
      values = ["/green/*"]
    }
  }
}

# -----------------------------------------------------
# ECS Cluster
# -----------------------------------------------------
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-bluegreen-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ecs-bluegreen-cluster"
  }
}

# -----------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------
resource "aws_cloudwatch_log_group" "blue_logs" {
  name              = "/ecs/blue"
  retention_in_days = 7

  tags = {
    Name = "blue-task-logs"
  }
}

resource "aws_cloudwatch_log_group" "green_logs" {
  name              = "/ecs/green"
  retention_in_days = 7

  tags = {
    Name = "green-task-logs"
  }
}

# -----------------------------------------------------
# IAM Role: ECS Task Execution Role
# -----------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ecs-task-execution-role"
  }
}

# -----------------------------------------------------
# Attach AmazonECSTaskExecutionRolePolicy
# -----------------------------------------------------
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ----------------------------------------
# BLUE Task Definition
# ----------------------------------------
resource "aws_ecs_task_definition" "blue_task" {
  family                   = "blue-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "blue-app"
    image     = "nginx:latest"
    essential = true

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.blue_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Name = "blue-task-definition"
  }
}

# ----------------------------------------
# GREEN Task Definition
# ----------------------------------------
resource "aws_ecs_task_definition" "green_task" {
  family                   = "green-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "green-app"
    image     = "nginx:latest"
    essential = true

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.green_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Name = "green-task-definition"
  }
}

# ----------------------------------------
# BLUE ECS Service
# ----------------------------------------
resource "aws_ecs_service" "blue_service" {
  name            = "blue-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.blue_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
 


  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue_tg.arn
    container_name   = "blue-app"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]

  tags = {
    Name = "blue-ecs-service"
  }
}

# ----------------------------------------
# GREEN ECS Service (Initially scaled to 0)
# ----------------------------------------
resource "aws_ecs_service" "green_service" {
  name            = "green-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.green_task.arn
  desired_count   = 0
  launch_type     = "FARGATE"
 


  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green_tg.arn
    container_name   = "green-app"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [
    aws_lb_listener.http_listener
  ]

  tags = {
    Name = "green-ecs-service"
  }
}

# -----------------------------------------------------
# IAM Role: CodeDeploy Service Role
# -----------------------------------------------------
# resource "aws_iam_role" "codedeploy_role" {
#   name = "CodeDeployServiceRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "codedeploy.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })

#   tags = {
#     Name = "codedeploy-service-role"
#   }
# }

# # -----------------------------------------------------
# # Attach AWSCodeDeployRoleForECS Policy
# # -----------------------------------------------------
# resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
#   role       = aws_iam_role.codedeploy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
# }

# # -----------------------------------------------------
# # CodeDeploy Application
# # -----------------------------------------------------
# resource "aws_codedeploy_app" "ecs_app" {
#   name             = "BlueGreenApp"
#   compute_platform = "ECS"

#   tags = {
#     Name = "ecs-bluegreen-app"
#   }
# }

# # -----------------------------------------------------
# # CodeDeploy Deployment Group
# # -----------------------------------------------------
# resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
#   app_name               = aws_codedeploy_app.ecs_app.name
#   deployment_group_name  = "BlueGreenDeploymentGroup"
#   service_role_arn       = aws_iam_role.codedeploy_role.arn
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

#   ecs_service {
#     cluster_name = aws_ecs_cluster.ecs_cluster.name
#     service_name = aws_ecs_service.blue_service.name
#   }

#   blue_green_deployment_config {
#     terminate_blue_instances_on_deployment_success {
#       action                           = "TERMINATE"
#       termination_wait_time_in_minutes = 1
#     }

#     deployment_ready_option {
#       action_on_timeout = "CONTINUE_DEPLOYMENT"
#     }
#   }

#   load_balancer_info {
#     target_group_pair_info {
#       prod_traffic_route {
#         listener_arns = [aws_lb_listener.http_listener.arn]
#       }

#       target_group {
#         name = aws_lb_target_group.blue_tg.name
#       }

#       target_group {
#         name = aws_lb_target_group.green_tg.name
#       }
#     }
#   }

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

#   tags = {
#     Name = "ecs-bluegreen-deployment-group"
#   }
# }