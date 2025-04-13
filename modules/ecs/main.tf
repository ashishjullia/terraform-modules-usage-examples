locals {
  ecs_environment_variables = [
    for name, value in var.environment_variables : {
      name  = name
      value = value
    }
  ]
  ecs_secrets = [
    for secret in var.container_secrets : {
      name      = secret.name
      valueFrom = secret.valueFrom
    }
  ]
}

resource "aws_ecs_cluster" "app_cluster" {
  name = var.name_of_ecs_cluster 
}

resource "aws_ecs_service" "app_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.app_cluster.id

  task_definition = var.ecs_task_definition_name
  desired_count   = var.ecs_desired_task_count
  launch_type     = var.ecs_task_launch_type

  # Network configuration for Fargate tasks
  network_configuration {
    subnets = var.aws_ecs_service_subnet_ids
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    # !!! IMPORTANT !!!
    # Set to true ONLY if using public subnets AND there isn't a NAT Gateway.
    # This assigns a public IP to each task, which is generally NOT recommended for backend services.
    # For private subnets + NAT Gateway/VPC Endpoints, set this to false.
    assign_public_ip = var.aws_ecs_service_assign_public_ip # CHANGE TO false for production with private subnets
  }

  # Link service to the ALB Target Group
  load_balancer {
    # target_group_arn = aws_lb_target_group.main.arn
    target_group_arn = var.alb_target_group_arn
    container_name   = var.ecs_container_name # Must match container name in task definition # This name must exactly match the name specified within the container_definitions for aws_ecs_task_definition.
    container_port   = var.ecs_container_definition_container_port # This port must exactly match the containerPort specified within the portMappings for aws_ecs_task_definition.
  }
}

resource "aws_ecs_task_definition" "app_nodejs_task_definition" {
  family                   = var.ecs_task_definition_name
  network_mode             = var.ecs_task_definition_network_work
  requires_compatibilities = var.ecs_task_definition_set_of_launch_types
  cpu                      = var.ecs_task_definition_cpu_units
  memory                   = var.ecs_task_definition_memory_units
  # execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn      = var.ecs_execution_role_arn
  # task_role_arn         = aws_iam_role.ecs_task_role.arn # ARN of IAM role that allows the Amazon ECS container task to make calls to other AWS services.

  # Define the container(s)
  container_definitions = jsonencode([
    {
      name      = var.ecs_container_name # Container name
      image     = var.ecs_container_image_uri
      cpu       = var.ecs_container_definition_cpu_units   # Can allocate specific CPU/memory per container or share task-level
      memory    = var.ecs_container_definition_memory_units
      essential = true              # If this container fails, the task stops
      portMappings = [
        {
          containerPort = var.ecs_container_definition_container_port # This is the port the application LISTENS ON inside the container.
          #hostPort      = var.ecs_container_definition_host_port # Not strictly needed for awsvpc so commenting this for "awsvpc mode with ALB to avoid confusion"
          protocol      = "tcp"
        }
      ]
      # Environment variables
      environment = local.ecs_environment_variables
      # Secrets from Secrets Manager / Parameter Store
      secrets = local.ecs_secrets
      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs" # Prefix for log streams within the group
        }
      }
    }
    # Add more containers here if needed (e.g., sidecars)
  ])
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg-for-cluster-${var.name_of_ecs_cluster}"
  description = "Allow traffic from ALB to Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    self = true
    description     = "self"
  }

  # Ingress: Allow traffic only from the ALB on the container port
  ingress {
    protocol        = "tcp"
    from_port       = var.ecs_container_definition_container_port
    to_port         = var.ecs_container_definition_container_port
    security_groups = var.alb_security_group
    description     = "Allow traffic from ALB"
  }

  # Egress: Allow all outbound traffic
  # Restrict this further in production if possible (e.g., only to NAT Gateway/Endpoints)
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.ecs_container_name}"
  retention_in_days = 7 
}
