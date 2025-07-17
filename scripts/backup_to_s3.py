# backup_to_s3.py
# Purpose: Backs up critical FastAPI files to S3.
# Security: Uses IAM role for S3 access, no hardcoded credentials.

import boto3
import os
from datetime import datetime

# Initialize S3 client
s3 = boto3.client('s3')
bucket = "my-backup-bucket" # TODO: Replace with your S3 bucket name
local_path = "/home/ec2-user/app/main.py"
s3_key = f"backups/main.py-{datetime.now().strftime('%Y-%m-%d')}"

# Upload file to S3
try:
    s3.upload_file(local_path, bucket, s3_key)
    print(f"Backed up {local_path} to s3://{bucket}/{s3_key}")
except Exception as e:
    print(f"Backup failed: {str(e)}")
