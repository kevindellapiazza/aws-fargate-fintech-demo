# --- NETWORK CONFIGURATION (VPC) ---
# Creates a dedicated VPC to isolate the Fargate resources.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "fintech-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["eu-west-2a", "eu-west-2b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  
  # DNS Hostnames are required for Fargate to resolve ECR endpoints
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# --- ECS CLUSTER ---
# The logical container for our Fargate services.
resource "aws_ecs_cluster" "main" {
  name = "fintech-cluster"
}

# --- IAM ROLES (Security) ---
# Task Execution Role: Allows the ECS Agent (Fargate) to make AWS API calls on your behalf.
# Required to pull images from ECR and push logs to CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "fintech-ecs-execution-role"
 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- SECURITY GROUPS (Firewall) ---
# Strict rules to allow traffic only on necessary ports.
resource "aws_security_group" "ecs_sg" {
  name        = "fintech-ecs-sg"
  description = "Allow HTTP traffic on port 80"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow HTTP from anywhere (Demo purpose)
  # In Production, this should be restricted to the Load Balancer SG only.
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Egress: Allow all outbound traffic (required to pull Docker images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# --- TASK DEFINITION ---
# The blueprint for our application container.
resource "aws_ecs_task_definition" "app" {
  family                   = "fintech-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU (Cost Optimized)
  memory                   = "512" # 512 MB RAM

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "fintech-container"
    image     = aws_ecr_repository.fintech_app_repo.repository_url
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# --- ECS SERVICE ---
# Ensures the application is running and self-healing.
resource "aws_ecs_service" "main" {
  name            = "fintech-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Single instance for cost saving

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Required for Fargate in public subnets to pull images
  }
}