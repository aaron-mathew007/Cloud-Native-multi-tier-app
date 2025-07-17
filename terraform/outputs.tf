# outputs.tf
# Purpose: Exposes key resource attributes for reference and debugging.

output "ec2_public_ip" {
  description = "Public IP of the FastAPI EC2 instance"
  value       = aws_instance.fastapi_server.public_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "s3_website_endpoint" {
  description = "S3 bucket website endpoint for frontend"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
