output "cost_explorer_policy_arn" {
  description = "The ARN of the Cost Explorer IAM Policy"
  value       = aws_iam_policy.cost_explorer_policy.arn
}

output "bedrock_invoke_policy_arn" {
  description = "The ARN of the Bedrock Invoke IAM Policy"
  value       = aws_iam_policy.bedrock_invoke_policy.arn
}
