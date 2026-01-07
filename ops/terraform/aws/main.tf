provider "aws" {
  region = "us-east-1"
}

# ==========================================
# VPC Module (Network Layer)
# ==========================================
# Creates the networking foundation:
# - VPC with CIDR 10.0.0.0/16
# - Public Subnets (for Load Balancers)
# - Private Subnets (for Apps and Databases)
# - NAT Gateway (allows private instances to access internet for updates)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name   = "amazon-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

# ==========================================
# EKS Cluster (Compute Layer)
# ==========================================
# Provision Elastic Kubernetes Service
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = "amazon-cluster"
  cluster_version = "1.27"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # Worker Nodes Group
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"] # Cost-effective instance type
    }
  }
}

# ==========================================
# RDS MySQL (Database Layer)
# ==========================================
# Managed Relational Database Service
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"
  identifier = "amazon-db"
  engine            = "mysql"
  engine_version    = "8.0"
  major_engine_version = "8.0"
  family            = "mysql8.0"
  instance_class    = "db.t3.micro" # Free tier eligible
  allocated_storage = 5
  username = "admin"
  port     = 3306
  subnet_ids = module.vpc.private_subnets # Securely placed in private subnet
}

# ==========================================
# ElastiCache Redis (Caching Layer)
# ==========================================
# Managed Redis for session storage and caching
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"
  
  cluster_id           = "amazon-redis"
  replication_group_id = "amazon-redis-rep-group"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t3.micro"
  parameter_group_name = "default.redis6.x"
  num_cache_nodes      = 1
  port                 = 6379
  subnet_ids           = module.vpc.private_subnets
}

# ==========================================
# Amazon MQ (RabbitMQ)
# ==========================================
# Managed RabbitMQ service for message queuing
# Replace module with direct resource due to registry issues
resource "aws_mq_broker" "rabbitmq" {
  broker_name = "amazon-mq"

  engine_type        = "RabbitMQ"
  engine_version     = "3.10.10"
  host_instance_type = "mq.t3.micro"
  
  publicly_accessible = false
  subnet_ids          = [module.vpc.private_subnets[0]]

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
  special = true
}
