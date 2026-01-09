output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS Control Plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "RDS MySQL Endpoint"
  value       = module.db.db_instance_endpoint
}

output "redis_endpoint" {
  description = "Redis Cache Endpoint"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "mq_broker_id" {
  description = "Amazon MQ Broker ID"
  value       = aws_mq_broker.rabbitmq.id
}

  description = "Amazon MQ Web Console URL"
  value       = aws_mq_broker.rabbitmq.instances[0].console_url
}

output "ecr_backend_url" {
  description = "ECR Repository URL for Backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "ECR Repository URL for Frontend"
  value       = aws_ecr_repository.frontend.repository_url
}
