# Drift Detective: CodeBuild + EventBridge

resource "aws_codebuild_project" "drift_detective" {
  name          = "drift-detective"
  description   = "Runs terraform plan daily to detect drift"
  build_timeout = "15"
  service_role  = aws_iam_role.codebuild_exec.arn # Assumes existing CodeBuild role

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/mkdevops89/amazon-clone-devops.git"
    buildspec = <<EOF
version: 0.2
phases:
  build:
    commands:
      - cd ops/terraform/aws
      - terraform init
      - terraform plan -detailed-exitcode
EOF
  }
}

resource "aws_cloudwatch_event_rule" "daily_drift_check" {
  name                = "daily-drift-check"
  description         = "Trigger Drift Detection at Midnight"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_codebuild" {
  rule      = aws_cloudwatch_event_rule.daily_drift_check.name
  target_id = "drift_detective"
  arn       = aws_codebuild_project.drift_detective.arn
  role_arn  = aws_iam_role.eventbridge_codepipeline.arn # Role to allow EventBridge to start Build
}

# --- MISSING IAM ROLES ---

# 1. CodeBuild Service Role
resource "aws_iam_role" "codebuild_exec" {
  name = "drift_detective_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# Attach Admin Access (since Terraform needs to read/write state and check all resources)
resource "aws_iam_role_policy_attachment" "codebuild_admin" {
  role       = aws_iam_role.codebuild_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 2. EventBridge Role (to trigger CodeBuild)
resource "aws_iam_role" "eventbridge_codepipeline" {
  name = "eventbridge_drift_trigger_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "eventbridge_start_build" {
  name = "eventbridge_start_codebuild"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["codebuild:StartBuild"]
      Resource = [aws_codebuild_project.drift_detective.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_attach" {
  role       = aws_iam_role.eventbridge_codepipeline.name
  policy_arn = aws_iam_policy.eventbridge_start_build.arn
}
