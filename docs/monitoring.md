# Monitoring Setup

## 🔍 Overview

This project includes a full monitoring stack using:

- **Prometheus**: Collects real-time metrics from the application and system.
- **Node Exporter**: Provides system-level metrics (CPU, memory, etc.).
- **Grafana**: Visualizes metrics using custom and pre-built dashboards.
- **CloudWatch (Manual)**: Used to check RDS metrics since YACE setup is skipped for Free Tier simplicity.

---

## Setup Instructions

1. **Prometheus**:
   - Installed on EC2 via user data script.
   - Configuration (`/opt/prometheus/prometheus.yml`):
     ```yaml
     global:
       scrape_interval: 15s
     scrape_configs:
       - job_name: 'node'
         static_configs:
           - targets: ['localhost:9100']
       - job_name: 'fastapi'
         static_configs:
           - targets: ['localhost:8000']
     ```
   - Access at `http://<ec2-public-ip>:9090`.

2. **Node Exporter**:
   - Installed on EC2 for system metrics (CPU, memory).
   - Runs on port 9100.

3. **Grafana**:
   - Installed on EC2, accessible at `http://<ec2-public-ip>:3000` (user: admin, password: admin).
   - Add Prometheus data source: `http://localhost:9090`.
   - Import dashboard with the following JSON:
     ```json
     {
       "panels": [
         {
           "title": "EC2 CPU Usage",
           "type": "timeseries",
           "targets": [
             {
               "expr": "rate(node_cpu_seconds_total{mode='user'}[5m])",
               "legendFormat": "CPU User"
             }
           ]
         },
         {
           "title": "API Error Rates",
           "type": "timeseries",
           "targets": [
             {
               "expr": "sum(rate(http_requests_total{status=~'4..|5..'}[5m]))",
               "legendFormat": "Error Rate"
             }
           ]
         }
       ]
     }
     ```

4. **RDS Monitoring**:
   - Use CloudWatch metrics (manually monitored in this setup due to YACE complexity in Free Tier).
   - Check `aws_rds_cpu_utilization_average` in CloudWatch.

## Screenshot Guidelines

- **Prometheus Targets**: Navigate to `http://<ec2-public-ip>:9090/targets` and screenshot the "Up" status for `node` and `fastapi`.
- **Grafana Dashboard**: Capture the dashboard with EC2 CPU and API error rate panels populated.

FreeableMemory

Use AWS CloudWatch console → RDS → Metrics tab.


