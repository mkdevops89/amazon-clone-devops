provider "aws" {
  region = var.region
}

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
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"
  
  # Fix: Ensure SG is created in Custom VPC
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  
  identifier = var.db_name
  engine            = "mysql"
  engine_version    = "8.0"
  major_engine_version = "8.0"
  family            = "mysql8.0"
  instance_class    = "db.t3.micro" # Free tier eligible
  allocated_storage = 5
  username = var.db_username
  port     = 3306
  subnet_ids = module.vpc.private_subnets
}

# ==========================================
# ElastiCache Redis (Caching Layer)
# ==========================================
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"
  
  
  security_group_ids   = [module.vpc.default_security_group_id] # Fix: Ensure SG is created in Custom VPC
  
  cluster_id           = var.redis_cluster_id
  replication_group_id = "${var.redis_cluster_id}-rep-group"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = "cache.t3.micro"
  parameter_group_name = "default.redis6.x"
  num_cache_nodes      = 1
  port                 = 6379
  subnet_ids           = module.vpc.private_subnets
  
  # Fix: Force creation of a unique subnet group for THIS VPC
  # Fix: Force unique name to avoid conflict with old VPC resource
  subnet_group_name   = "${var.redis_cluster_id}-subnet-group-v3"
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
  
  # Fix: Must explicitly assign a Security Group from the SAME VPC
  security_groups     = [module.vpc.default_security_group_id]

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
