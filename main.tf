# Medusa Backend Deployment on AWS ECS Fargate using Terraform

provider "aws" {
  region = "us-east-1"
}

########################
# VPC Configuration
########################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "medusa-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  tags = {
    Name = "medusa-vpc"
  }
}

########################
# ECS Cluster
########################
resource "aws_ecs_cluster" "medusa" {
  name = "medusa-cluster"
}

########################
# IAM Roles for ECS Task Execution
########################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

########################
# RDS PostgreSQL Instance
########################
resource "aws_db_instance" "medusa_db" {
  identifier         = "medusa-db"
  allocated_storage  = 20
  engine             = "postgres"
  engine_version     = "14.1"
  instance_class     = "db.t3.micro"
  name               = "medusadb"
  username           = "medusa"
  password           = "medusapassword"
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.medusa.name
}

resource "aws_db_subnet_group" "medusa" {
  name       = "medusa-db-subnet-group"
  subnet_ids = module.vpc.public_subnets
}

resource "aws_security_group" "db_sg" {
  name        = "medusa-db-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# Redis (Optional) – Use Elasticache
########################
# You can add an Elasticache Redis setup here

########################
# ECS Task Definition & Service (Placeholder)
########################
# You will define this after you push Docker image to ECR
# This includes container definitions, image URL, env variables, etc.

# Tip: Use variables for sensitive values
