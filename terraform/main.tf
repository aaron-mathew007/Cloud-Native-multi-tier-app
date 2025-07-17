# main.tf
# Purpose: Defines core AWS infrastructure including VPC, EC2 instance for FastAPI, and RDS PostgreSQL.
# Uses AWS Free Tier eligible resources (t2.micro, db.t2.micro) and secure configurations.
# Security: IAM roles, security groups, and private subnets limit exposure.

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "my-terraform-state" # TODO: Replace with your S3 bucket name
    key    = "cloud-native-app/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1" # Free Tier available in us-east-1
  # Credentials managed via AWS CLI or IAM role; avoid hardcoding
}

# VPC with public and private subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "cloud-native-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost optimization for Free Tier

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security group for EC2 (FastAPI, Prometheus, Grafana)
resource "aws_security_group" "ec2_sg" {
  name        = "ec Tokens:
  description = "Allow HTTP, SSH, Prometheus, Grafana"
  vpc_id      = module.vpc.vpc_id

  # HTTP for FastAPI
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FastAPI port
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to trusted IPs in production
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to monitoring network
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to admin IPs
  }

  # SSH for debugging
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # Only EC2 can access
  }
}

# RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t2.micro" # Free Tier eligible
  db_name                = "mydatabase"
  username               = "admin"
  password               = "securepassword" # TODO: Use AWS Secrets Manager
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# IAM role for EC2 to access RDS and CloudWatch
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2-policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:Describe*",
          "cloudwatch:GetMetric*",
          "cloudwatch:ListMetrics",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 instance for FastAPI
resource "aws_instance" "fastapi_server" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 (Free Tier)
  instance_type          = "t2.micro" # Free Tier eligible
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    # Install dependencies
    yum update -y
    yum install -y python3 git
    pip3 install fastapi uvicorn prometheus-fastapi-instrumentator sqlalchemy psycopg2-binary

    # Clone repository and deploy FastAPI app
    git clone <your-repo-url> /home/ec2-user/app # TODO: Replace with your GitHub repo URL
    cd /home/ec2-user/app
    nohup uvicorn main:app --host 0.0.0.0 --port 8000 &

    # Install Prometheus
    curl -LO https://github.com/prometheus/prometheus/releases/download/v2.41.0/prometheus-2.41.0.linux-amd64.tar.gz
    tar xvfz prometheus-2.41.0.linux-amd64.tar.gz
    mv prometheus-2.41.0.linux-amd64 /opt/prometheus
    cat << 'EOT' > /opt/prometheus/prometheus.yml
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'node'
        static_configs:
          - targets: ['localhost:9100']
      - job_name: 'fastapi'
        static_configs:
          - targets: ['localhost:8000']
    EOT
    nohup /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml &

    # Install Node Exporter
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
    tar xvfz node_exporter-1.5.0.linux-amd64.tar.gz
    mv node_exporter-1.5.0.linux-amd64 /opt/node_exporter
    nohup /opt/node_exporter/node_exporter &

    # Install Grafana
    yum install -y https://dl.grafana.com/oss/release/grafana-9.5.3-1.x86_64.rpm
    systemctl start grafana-server
    systemctl enable grafana-server
  EOF

  tags = {
    Name        = "FastAPI-Server"
    Terraform   = "true"
    Environment = "dev"
  }
}
