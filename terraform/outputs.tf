output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}



####################### Output #######################

alb_dns = "devops-app-alb-1234567890.us-east-1.elb.amazonaws.com"
ecs_cluster_name = "devops-sample-cluster"
service_name = "devops-app-service"
