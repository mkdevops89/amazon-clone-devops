# AWS Budget: Hard ceiling of $50/month
resource "aws_budgets_budget" "monthly_cost" {
  name              = "monthly-budget-50"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  # Alert 1: Forecast to exceed 80% ($40)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [aws_sns_topic.alerts.arn]
  }

  # Alert 2: Actual spend exceeds 90% ($45)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.alerts.arn]
  }
}
