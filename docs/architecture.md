# Architecture Overview

## 🧭 System Diagram

```mermaid
graph TD
    A[Internet] --> B[Route53 Health Check]
    B --> C[VPC]
    C --> D[Public Subnet]
    C --> E[Private Subnet]
    D --> F[EC2: FastAPI, Prometheus, Grafana, Node Exporter]
    E --> G[RDS PostgreSQL]
    D --> H[S3: Frontend]
    F --> I[S3: Backups]



