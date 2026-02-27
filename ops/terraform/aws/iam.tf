# ==========================================
# IAM Policy for Cost Explorer Access
# ==========================================
resource "aws_iam_policy" "cost_explorer_policy" {
  name        = "AmazonCloneCostExplorerPolicy"
  description = "Allows EKS nodes to query AWS Cost Explorer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# IAM Policy for AWS Bedrock Access
# ==========================================
resource "aws_iam_policy" "bedrock_invoke_policy" {
  name        = "AmazonCloneBedrockInvokePolicy"
  description = "Allows EKS nodes to invoke Bedrock models (Claude 3 Haiku)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
