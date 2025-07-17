# Terraform Modules Documentation

## Overview

The Terraform configuration is modularized for reusability. Key modules are implemented in `main.tf` and `s3.tf`.

## Modules

### VPC
- **Source**: `terraform-aws-modules/vpc/aws`
- **Purpose**: Creates a VPC with public and private subnets.
- **Usage**:
  ```hcl
  module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    name    = "cloud-native-vpc"
    cidr    = "10.0.0.0/16"
    azs     = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
    enable_nat_gateway = true
    single_nat_gateway = true
  }

**EC2**

- **Purpose**: Deploys a t2.micro instance with FastAPI, Prometheus, and Grafana.
- **Key Features**: IAM role for CloudWatch/S3 access, user data for automated setup.
- **Usage**: See main.tf for configuration.

**RDS**

- **Purpose**: Deploys a db.t2.micro PostgreSQL instance in private subnets.
- **Security**: Accessible only from EC2 security group.
- **Usage**: See main.tf for configuration.

**S3**

- **Purpose**: Hosts static frontend with public read access and CORS.
- **Usage**: See s3.tf for configuration.



## Scripts

### scripts/backup.sh

```bash
#!/bin/bash
# backup.sh
# Purpose: Creates daily RDS snapshots and triggers S3 backup.
# Warning: Ensure AWS CLI is configured with appropriate credentials.

# Create RDS snapshot
SNAPSHOT_ID="my-snapshot-$(date +%Y-%m-%d)"
aws rds create-db-snapshot \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --db-instance-identifier my-rds-instance # TODO: Replace with your RDS instance identifier

# Clean up snapshots older than 7 days
aws rds describe-db-snapshots \
    --db-instance-identifier my-rds-instance \
    --query 'DBSnapshots[?SnapshotCreateTime<`$(date -d "7 days ago" --iso-8601)`].[DBSnapshotIdentifier]' \
    --output text | xargs -I {} aws rds delete-db-snapshot --db-snapshot-identifier {}

# Trigger S3 backup
python3 /home/ec2-user/scripts/backup_to_s3.py

