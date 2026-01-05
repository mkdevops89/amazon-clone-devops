# ==========================================
# Route53 (DNS)
# ==========================================
variable "domain_name" {
  default = "amazon-clone.com" # Change this to your real domain
}

# 1. Create a Hosted Zone
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

# 2. Create A Record (Alias to Load Balancer)
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    # Note: In a real scenario, you get this DNS name from the Kubernetes Ingress Load Balancer
    name                   = "dualstack.k8s-load-balancer-123456789.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K" # Zone ID for AWS ELB in us-east-1
    evaluate_target_health = true
  }
}
