# ==========================================
# ECR Repository: Backend
# ==========================================
resource "aws_ecr_repository" "backend" {
  name                 = "amazon-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Service     = "backend"
  }
}

# ==========================================
# ECR Repository: Frontend
# ==========================================
resource "aws_ecr_repository" "frontend" {
  name                 = "amazon-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Service     = "frontend"
  }
}

# ==========================================
# Lifecycle Policy (Best Practice: Cost Savings)
# Keep only the last 10 images to avoid storage costs
# ==========================================
resource "aws_ecr_lifecycle_policy" "backend_policy" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend_policy" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ==========================================
# ECR Repository: Cost Exporter
# ==========================================
resource "aws_ecr_repository" "cost_exporter" {
  name                 = "cost-exporter"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Service     = "cost-exporter"
  }
}

resource "aws_ecr_lifecycle_policy" "cost_exporter_policy" {
  repository = aws_ecr_repository.cost_exporter.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
