output "alb_address" {
  description = "The address of the ALB"
  value       = "https://${module.alb.dns_name}"
}