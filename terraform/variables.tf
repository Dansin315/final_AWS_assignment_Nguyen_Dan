variable "aws_region" {
  description = "AWS region used by the AWS Academy lab"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used in AWS resource names"
  type        = string
  default     = "final-wp-ha"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.name_prefix))
    error_message = "name_prefix must be 3-21 characters and use lowercase letters, numbers, and hyphens."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the WordPress web servers"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "HTTP application port used by Apache/WordPress"
  type        = number
  default     = 80
}

variable "enable_ssh" {
  description = "Whether to allow SSH access for troubleshooting"
  type        = bool
  default     = false
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2 instances when enable_ssh is true"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH. Leave null when SSH is not needed."
  type        = string
  default     = null
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "db_instance_class" {
  description = "RDS instance class for the lab database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial RDS database name for WordPress"
  type        = string
  default     = "wordpressdb"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,63}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_master_username" {
  description = "RDS master username used by this WordPress instance"
  type        = string
  default     = "wpadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.db_master_username))
    error_message = "db_master_username must start with a letter and contain up to 16 letters, numbers, or underscores."
  }
}

variable "db_master_password" {
  description = "RDS master password. Set with TF_VAR_db_master_password, not terraform.tfvars."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_master_password) >= 8 && length(var.db_master_password) <= 41
    error_message = "db_master_password must be 8-41 characters."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9_+=,.!-]+$", var.db_master_password))
    error_message = "db_master_password should use only letters, numbers, and _+=,.!- for this lab."
  }
}

variable "wordpress_table_prefix" {
  description = "WordPress database table prefix"
  type        = string
  default     = "wp_"

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.wordpress_table_prefix))
    error_message = "wordpress_table_prefix may contain only letters, numbers, and underscores."
  }
}
