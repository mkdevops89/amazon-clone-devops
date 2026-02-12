variable "lambda_role_name" {
  default = "cost_optimizer_role"
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "cost_optimizer_policy"
  description = "Permissions for Cost Terminator and Auto-Healer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:DescribeVolumes",
          "ec2:DeleteVolume",
          "ec2:DescribeAddresses",
          "ec2:ReleaseAddress",
          "ec2:RevokeSecurityGroupIngress",
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig",
          "ssm:SendCommand",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "auto-healer-alerts"
}

# 1. Cost Terminator Lambda
resource "archive_file" "cost_optimizer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/cost_optimizer"
  output_path = "${path.module}/cost_optimizer.zip"
}

resource "aws_lambda_function" "cost_optimizer" {
  filename         = archive_file.cost_optimizer_zip.output_path
  function_name    = "cost_terminator"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = archive_file.cost_optimizer_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

# 2. EventBridge Schedules (Cron)
resource "aws_cloudwatch_event_rule" "nightly_stop" {
  name                = "nightly-stop"
  description         = "Trigger Cost Terminator at 9:15 PM CST"
  schedule_expression = "cron(15 3 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_stop" {
  rule      = aws_cloudwatch_event_rule.nightly_stop.name
  target_id = "cost_terminator_stop"
  arn       = aws_lambda_function.cost_optimizer.arn
  input     = jsonencode({"action": "stop"})
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nightly_stop.arn
}



resource "aws_cloudwatch_event_rule" "morning_start" {
  name                = "morning-start"
  description         = "Trigger Cost Terminator at 9 AM CST"
  schedule_expression = "cron(0 15 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_start" {
  rule      = aws_cloudwatch_event_rule.morning_start.name
  target_id = "cost_terminator_start"
  arn       = aws_lambda_function.cost_optimizer.arn
  input     = jsonencode({"action": "start"})
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.morning_start.arn
}
