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
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig",
          "ssm:SendCommand",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
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
  handler         = "index.lambda_handler"
  source_code_hash = archive_file.cost_optimizer_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 300
}

# 2. EventBridge Schedules (Cron)
resource "aws_cloudwatch_event_rule" "nightly_stop" {
  name                = "nightly-stop"
  description         = "Trigger Cost Terminator at 8 PM"
  schedule_expression = "cron(0 20 * * ? *)"
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

# 3. Auto-Healer Lambda
resource "archive_file" "auto_healer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/auto_healer"
  output_path = "${path.module}/auto_healer.zip"
}

resource "aws_lambda_function" "auto_healer" {
  filename         = archive_file.auto_healer_zip.output_path
  function_name    = "auto_healer"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.lambda_handler"
  source_code_hash = archive_file.auto_healer_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60
}
