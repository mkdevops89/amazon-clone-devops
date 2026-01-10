provider "aws" {
  region = var.region
}

# Used to dynamically fetch the current user's ARN for EKS Admin access
data "aws_caller_identity" "current" {}

# ==========================================
# VPC Module (Network Layer)
# ==========================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name   = var.vpc_name
  cidr   = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  # Tags required for EKS Load Balancer discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# ==========================================
# EKS Cluster (Compute Layer)
# ==========================================
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  
  # Fix: Enable Public Access for kubectl from local machine
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Worker Nodes Group
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"] # Cost-effective instance type
    }
  }

  # Fix: Grant Cluster Admin permissions to the current caller
  # Fix: Grant Cluster Admin permissions to the current caller
  enable_cluster_creator_admin_permissions = true

  # Fix: Allow Inbound Traffic to Worker Nodes for NodePorts (Required for LoadBalancers)
  node_security_group_additional_rules = {
    ingress_allow_8080 = {
      description = "Allow Inbound 8080 for Backend (Force Apply)"
      protocol    = "tcp"
      from_port   = 8080
      to_port     = 8080
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_allow_3000 = {
      description = "Allow Inbound 3000 for Frontend"
      protocol    = "tcp"
      from_port   = 3000
      to_port     = 3000
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# ==========================================
# Security Groups (Explicitly for Custom VPC)
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "${var.db_name}-sg"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.redis_cluster_id}-sg"
  description = "Security group for Redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "mq_sg" {
  name        = "amazon-mq-sg"
  description = "Security group for Amazon MQ"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

# ==========================================
# RDS MySQL (Database Layer)
# ==========================================
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"
  
  identifier        = var.db_name
  engine            = "mysql"
  engine_version    = "8.0"
  major_engine_version = "8.0"
  family            = "mysql8.0"
  instance_class    = "db.t3.micro" # Free tier eligible
  allocated_storage = 5
  username          = var.db_username
  port              = 3306
  
  # Fix: Skip snapshot on destroy for Dev environments to allow clean teardown
  skip_final_snapshot = true
  
  # Network & Security
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  subnet_ids             = module.vpc.private_subnets
  create_db_subnet_group = true
  # Dynamic naming prevents collision with ghost resources
  db_subnet_group_name   = "${var.db_name}-${module.vpc.vpc_id}-subnet-group"
}

# ==========================================
# ElastiCache Redis (Caching Layer)
# ==========================================
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"
  
  cluster_id           = var.redis_cluster_id
  replication_group_id = "${var.redis_cluster_id}-rep-group"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t3.micro"
  parameter_group_name = "default.redis6.x"
  num_cache_nodes      = 1
  port                 = 6379
  
  # Network & Security
  vpc_id                = module.vpc.vpc_id
  create_security_group = false
  security_group_ids    = [aws_security_group.redis_sg.id]
  
  subnet_ids            = module.vpc.private_subnets
  create_subnet_group   = true
  # Dynamic naming prevents collision with ghost resources
  subnet_group_name     = "${var.redis_cluster_id}-${module.vpc.vpc_id}-subnet-group"
}

# ==========================================
# Amazon MQ (RabbitMQ)
# ==========================================
resource "aws_mq_broker" "rabbitmq" {
  broker_name = "amazon-mq"

  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = "mq.t3.micro"
  
  # Required for RabbitMQ 3.13+
  auto_minor_version_upgrade = true
  
  publicly_accessible = false
  subnet_ids          = [module.vpc.private_subnets[0]]
  
  # Explicit Security Group
  security_groups     = [aws_security_group.mq_sg.id]

  user {
    username = "admin"
    password = random_password.mq_password.result
  }

  logs {
    general = true
  }
}

resource "random_password" "mq_password" {
  length  = 16
  special = false # Simplest fix: RabbitMQ allows alphanumeric without issues, or we can use specific allowed chars.
  # If we really want special chars, we'd use: override_special = "_%@"
}
