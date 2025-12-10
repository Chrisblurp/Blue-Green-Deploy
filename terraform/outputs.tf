output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "blue_service_name" {
  description = "Name of the blue ECS service"
  value       = aws_ecs_service.blue_service.name
}

output "green_service_name" {
  description = "Name of the green ECS service"
  value       = aws_ecs_service.green_service.name
}

output "active_color" {
  value = var.active_color
}



# output "codedeploy_app_name" {
#   description = "CodeDeploy application name"
#   value       = aws_codedeploy_app.ecs_app.name
# }

# output "codedeploy_deployment_group_name" {
#   description = "CodeDeploy deployment group name"
#   value       = aws_codedeploy_deployment_group.ecs_deployment_group.deployment_group_name
# }