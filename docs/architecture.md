# Architecture

## Goal

The project creates a small WordPress web service that demonstrates high availability and scalability concepts from the AWS class labs.

## Components

### EC2

EC2 instances run Amazon Linux 2023, Apache HTTP Server, PHP, and WordPress. The installation is automated by `terraform/user-data.sh`.

### Application Load Balancer

The ALB receives public HTTP traffic on port 80 and forwards requests to the target group.

### Auto Scaling Group

The ASG keeps the desired number of WordPress EC2 instances running across two subnets. If an instance becomes unhealthy according to ELB health checks, the ASG can replace it.

### RDS MySQL

RDS stores the WordPress database. The RDS security group only allows MySQL traffic from the WordPress web server security group.

### Benchmarking

The `scripts/` folder contains the ApacheBench scripts from the benchmarking lab. They can test latency, throughput, concurrency behavior, p95 latency, and failed requests.

## Security Group Flow

```text
User browser -> ALB security group -> Web security group -> RDS security group
```

- ALB allows public HTTP on port 80.
- Web instances allow HTTP only from the ALB security group.
- RDS allows MySQL only from the web security group.
- SSH is disabled by default and can be enabled only for troubleshooting.

## Health Checks

The target group checks `/health.html`. This file is created by user data and includes the instance id, availability zone, database host, and database name.
