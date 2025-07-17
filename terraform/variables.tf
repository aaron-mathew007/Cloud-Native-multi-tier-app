# variables.tf
# Purpose: Defines reusable variables for Terraform configurations.
# Allows customization without modifying main.tf or s3.tf.

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for frontend"
  type        = string
  default     = "my-frontend-bucket" # TODO: Replace with unique name
}

variable "db_password" {
  description = "RDS PostgreSQL password"
  type        = string
  sensitive   = true
  default     = "securepassword" # TODO: Replace with Secrets Manager reference
}
