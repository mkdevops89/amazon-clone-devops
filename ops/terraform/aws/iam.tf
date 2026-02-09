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
