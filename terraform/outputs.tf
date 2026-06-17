output "alb_dns_name" {
  description = "Open this ALB DNS name in the browser to reach WordPress"
  value       = aws_lb.web.dns_name
}

output "wordpress_url" {
  description = "HTTP URL for the WordPress site through the ALB"
  value       = "http://${aws_lb.web.dns_name}/"
}

output "target_group_name" {
  description = "Target group used by the ALB and Auto Scaling Group"
  value       = aws_lb_target_group.web.name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.wordpress.name
}

output "rds_endpoint" {
  description = "Private RDS endpoint used by WordPress"
  value       = aws_db_instance.wordpress.address
}
