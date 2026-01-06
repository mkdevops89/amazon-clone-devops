output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS database"
  value       = module.db.db_instance_endpoint
}

output "redis_endpoint" {
  description = "The endpoint of the Redis ElastiCache cluster"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "mq_broker_console_url" {
  description = "The URL of the Amazon MQ Web Console"
  value       = aws_mq_broker.rabbitmq.instances[0].console_url
}

output "mq_broker_endpoints" {
  description = "The endpoints for the Amazon MQ Broker"
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints
}
