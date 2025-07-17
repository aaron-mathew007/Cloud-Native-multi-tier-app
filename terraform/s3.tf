# s3.tf
# Purpose: Configures S3 bucket for hosting static React/HTML frontend.
# Security: Public read access with CORS for API integration.
# Cost: Uses Free Tier eligible S3 storage.

resource "aws_s3_bucket" "frontend" {
  bucket = "my-frontend-bucket" # TODO: Replace with unique bucket name

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"] # TODO: Restrict to your domain
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# Sample index.html for frontend
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.bucket
  key          = "index.html"
  source       = "${path.module}/../app/index.html"
  content_type = "text/html"
}
