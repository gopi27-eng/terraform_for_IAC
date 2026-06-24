output "load_balancer_dns_name" {
  description = "The public URL of your web application load balancer"
  value       = aws_lb.my_alb.dns_name
}