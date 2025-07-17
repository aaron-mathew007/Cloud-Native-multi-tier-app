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
