output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnets" {
  value = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "eks_sg_id" {
  value = aws_security_group.eks-sg.id
}

output "rds_sg_id" {
  value = aws_security_group.RDS-sg.id
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

output "alb_dns_name" {
  description = "alb dns name to attach to frontend"
  value = aws_lb.app_alb.dns_name
}

output "alb_arn" {
  description = "arn of application load balancer"
  value = aws_lb.app_alb.arn
}

output "frontend_url" {
  value = aws_s3_bucket_website_configuration.static.website_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}