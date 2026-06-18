# Final AWS Web Service Project: WordPress HA with ALB, ASG, RDS, and Benchmarking

This repository is a small AWS-based web service project that combines the class concepts used in the attached labs:

- Terraform Infrastructure as Code
- EC2 web servers
- Application Load Balancer
- Auto Scaling Group for high availability
- RDS MySQL database for WordPress
- ApacheBench benchmarking scripts

The service deploys WordPress on EC2 instances managed by an Auto Scaling Group. The instances are registered behind an Application Load Balancer. WordPress uses a private RDS MySQL database instead of a local MariaDB database, so replacement EC2 instances can reconnect to the same database.

## Architecture

```text
Internet
   |
   v
Application Load Balancer :80
   |
   v
Target Group health check: /health.html
   |
   v
Auto Scaling Group across two default-VPC subnets
   |
   v
EC2 WordPress instances on Amazon Linux 2023
   |
   v
Private RDS MySQL database
```

## Repository Structure

```text
.
├── README.md
├── docs
│   ├── architecture.md
│   ├── deployment.md
│   └── benchmarking.md
├── scripts
│   ├── analyze-summary.sh
│   ├── run-http-benchmark.sh
│   └── run-sample-scenarios.sh
└── terraform
    ├── .gitignore
    ├── main.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    ├── user-data.sh
    ├── variables.tf
    └── versions.tf
└── wp-content
    └── themes
         └── aws-cards-market-theme.zip
```

## Requirements

- AWS Academy or AWS CLI credentials configured in the shell
- Terraform >= 1.5.0
- A default VPC with at least two subnets in the selected AWS region
- ApacheBench for the benchmarking part

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
export TF_VAR_db_master_password='AWS2026!'
terraform init
terraform fmt
terraform validate
terraform plan -out plan.out
terraform apply plan.out
```

After apply finishes, open the 
`http://final-wp-ha-alb-577588890.us-east-1.elb.amazonaws.com` output in a browser.

## Benchmark

From the repository root:

```bash
TARGET_URL="http://final-wp-ha-alb-577588890.us-east-1.elb.amazonaws.com" bash scripts/run-sample-scenarios.sh
bash scripts/analyze-summary.sh
```

The benchmark results are written to `results/`.

## Destroy

```bash
cd terraform
terraform destroy
```

## UML

```mermaid
flowchart LR
    User["User Browser"]
    Bench["ApacheBench scripts<br/>scripts/<br/>latency, throughput,<br/>concurrency, p95,<br/>failed requests"]
    UserData["terraform/user-data.sh<br/>installs Apache, PHP,<br/>WordPress and /health.html"]

    subgraph AWS["AWS Cloud"]
      subgraph VPC["VPC"]
        subgraph PublicEntry["Public entry"]
          ALB["Application Load Balancer<br/>HTTP listener :80<br/>ALB Security Group"]
          TG["Target Group<br/>WordPress EC2 targets<br/>health check: /health.html"]
        end

        subgraph ASG["Auto Scaling Group<br/>desired WordPress instances across two subnets"]
          EC2A["EC2 WordPress Instance A<br/>Amazon Linux 2023<br/>Apache HTTP Server<br/>PHP<br/>WordPress"]
          EC2B["EC2 WordPress Instance B<br/>Amazon Linux 2023<br/>Apache HTTP Server<br/>PHP<br/>WordPress"]
        end

        RDS[("RDS MySQL<br/>WordPress database<br/>Port 3306<br/>RDS Security Group")]
      end
    end

    User -->|"HTTP :80 public access"| ALB
    ALB -->|"forward requests"| TG
    TG -->|"HTTP :80 if healthy"| EC2A
    TG -->|"HTTP :80 if healthy"| EC2B
    TG -.->|"GET /health.html"| EC2A
    TG -.->|"GET /health.html"| EC2B
    EC2A -->|"MySQL :3306"| RDS
    EC2B -->|"MySQL :3306"| RDS
    UserData -.->|"automated setup"| EC2A
    UserData -.->|"automated setup"| EC2B
    Bench -->|"ApacheBench traffic"| ALB
```

## Security Group Flow

```mermaid
flowchart LR
    Browser["User browser"]
    ALBSG["ALB security group<br/>allows public HTTP :80"]
    WebSG["Web security group<br/>allows HTTP only from ALB SG"]
    RDSSG["RDS security group<br/>allows MySQL only from Web SG"]
    Browser --> ALBSG --> WebSG --> RDSSG
```




