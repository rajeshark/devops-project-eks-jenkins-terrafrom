output "vpc_id"{
    value=aws_vpc.my_vpc_1.id
}
output "public_subnets"{
    value=aws_subnet.public_1.id  
}
output"private_subnets"{
    value=aws_subnet.private_1.id
}
output "alb_sg_id" {
    value=aws_security_group.alb_sg.id
}
output "eks_sg_id" {
    value=aws_security_group.eks-sg.id
}
output "rds_sg_id"{
    value=aws_security_group.RDS-sg
}
output "db_endpoint"{
    value=aws_db_instance.postgres.address
}
output "alb_dns_name"{
    description = "alb dns name to attch to forntend"
    value = aws_lb.app_alb.dns_name
}
output "alb_arn"{
    description = "arn of application load balancer"
    value=aws_lb.app_alb.arn
}
output "frontend_url" {
  value=aws_s3_bucket_website_configuration.static.website_endpoint
}
