# Deployment Guide

## 1. Prepare AWS credentials

Use the AWS Academy lab credentials or your AWS CLI configuration. Do not commit credentials to GitHub.

## 2. Configure Terraform variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if you need a different region, instance type, or Auto Scaling size.

Set the database password through an environment variable:

```bash
export TF_VAR_db_master_password='Use-A-Lab-Only-Password-Here'
```

## 3. Run Terraform

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out plan.out
terraform apply plan.out
```

## 4. Open WordPress

After apply finishes, copy the `wordpress_url` output into your browser.

The first request may take time because EC2 user data installs Apache, PHP, MariaDB client tools, and WordPress, then connects to RDS.

## 5. Verify high availability

In the AWS console:

1. Open EC2 > Load Balancers and check that the ALB is active.
2. Open EC2 > Target Groups and check that targets are healthy.
3. Open EC2 > Auto Scaling Groups and confirm the desired number of instances is running.
4. Terminate one WordPress instance and confirm the ASG launches a replacement.

## 6. Clean up

```bash
terraform destroy
```
