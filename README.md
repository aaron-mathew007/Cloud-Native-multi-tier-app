# Cloud-Native Multi-Tier Application

This project deploys a production-grade cloud-native application on AWS Free Tier, featuring:
- **Frontend**: Static HTML/React on S3.
- **Backend**: FastAPI on EC2 with Prometheus metrics.
- **Database**: PostgreSQL on RDS with connection pooling.
- **Monitoring**: Prometheus and Grafana for EC2, FastAPI, and RDS metrics.
- **Resilience**: Daily backups and Route53 health checks.

## Deployment Instructions

1. **Prerequisites**:
   - AWS account with Free Tier.
   - Terraform >= 1.0.0.
   - AWS CLI configured with IAM credentials.
   - Python 3.8+ for scripts.

2. **Deploy Infrastructure**:
   ```bash
   cd terraform
   terraform init
   terraform apply

  
  Update variables.tf with your bucket name and DB password.
  TODO: Create S3 bucket for Terraform state (my-terraform-state).


2. **Deploy FastAPI:**
  EC2 user data automatically clones the repo and starts FastAPI.
  Access at http://<ec2-public-ip>:8000/health.

3.**Deploy Frontend:**
  Upload app/index.html to S3 bucket via Terraform.
  Access at <s3-website-endpoint>.

4.**Set Up Monitoring:**
  Prometheus: http://<ec2-public-ip>:9090.
  Grafana: http://<ec2-public-ip>:3000 (admin/admin).
  Follow docs/monitoring.md for dashboard setup.

5.**Configure Backups:**  
  Schedule scripts/backup.sh via cron:
    crontab -e
    0 2 * * * /home/ec2-user/scripts/backup.sh
