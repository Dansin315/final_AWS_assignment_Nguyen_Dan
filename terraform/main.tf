# Final wrap-up project: WordPress web service with ALB, ASG, and RDS.
# This keeps the same default-VPC lab style used in the previous Terraform projects.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default_vpc" {
  for_each = toset(data.aws_subnets.default_vpc.ids)
  id       = each.value
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  subnets_by_az = {
    for _, subnet in data.aws_subnet.default_vpc :
    subnet.availability_zone => subnet.id...
  }

  selected_azs = slice(sort(keys(local.subnets_by_az)), 0, 2)
  selected_subnet_ids = [
    for az in local.selected_azs : sort(local.subnets_by_az[az])[0]
  ]

  alb_name          = substr("${var.name_prefix}-alb", 0, 32)
  target_group_name = substr("${var.name_prefix}-tg", 0, 32)

  common_tags = {
    Course  = "cloud-computing-aws"
    Project = "final-wordpress-ha-rds"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow public HTTP traffic to the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound HTTP from the internet to the ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Allow the ALB to forward traffic and perform health checks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allow WordPress HTTP traffic from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Only the ALB security group may reach WordPress"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []

    content {
      description = "Optional SSH access for troubleshooting"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_cidr]
    }
  }

  egress {
    description = "Allow package downloads and RDS access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-web-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow MySQL access only from the WordPress web security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow MySQL from WordPress web instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow outbound responses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = local.selected_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "wordpress" {
  identifier             = "${var.name_prefix}-mysql"
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  engine                 = "mysql"
  instance_class         = var.db_instance_class
  username               = var.db_master_username
  password               = var.db_master_password
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  storage_type            = "gp2"
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-mysql"
  })
}

resource "aws_lb_target_group" "web" {
  name        = local.target_group_name
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    protocol            = "HTTP"
    path                = "/health.html"
    matcher             = "200"
    port                = "traffic-port"
  }

    stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }

  tags = merge(local.common_tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb" "web" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.selected_subnet_ids

  tags = merge(local.common_tags, {
    Name = local.alb_name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_launch_template" "wordpress" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  name_prefix            = var.name_prefix
  db_name                = var.db_name
  db_username            = var.db_master_username
  db_password            = var.db_master_password
  db_host                = aws_db_instance.wordpress.address
  db_port                = aws_db_instance.wordpress.port
  wordpress_table_prefix = var.wordpress_table_prefix
  theme_zip_url          = var.theme_zip_url
  }))

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${var.name_prefix}-wordpress"
    })
  }
}

resource "aws_autoscaling_group" "wordpress" {
  name                      = "${var.name_prefix}-asg"
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = local.selected_subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-wordpress-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Course"
    value               = local.common_tags.Course
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = local.common_tags.Project
    propagate_at_launch = true
  }
}
