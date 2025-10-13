#alb security group
resource "aws_security_group" "alb_sg" {
    name="${var.project_name}-alb-sg"
    description = "allow HTTP/HTTPS"
    vpc_id = var.vpc_id
    ingress  {
        description="HTTP from anyware"
        from_port=80
        to_port=80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTPS from anyware"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
    tags={
        Name="${var.project_name}-alb-sg"
    }
}
# eks and ecs security group
resource "aws_security_group" "eks-sg" {
    name="${project_name}-eks-sg"
    description = "allow trafic from alb and eks services backends"
    vpc_id = var.vpc_id
    dynamic "ingress" {
        for_each = var.backend_ports
        content {
          description = "allow alb to eks service ports"
          from_port = ingress.value
          to_port = ingress.value
          protocol = "tcp"
          security_groups = [aws_security_group.alb_sg.id]
        }
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags={
        Name="${var.project_name}-eks-sg"
    }
}
#RDS postgres security group
resource "aws_security_group" "RDS-sg" {
    name="${var.project_name}-RDS-sg"
    description = "allow eks nodes acesss to RDS"
    vpc_id = var.vpc_id
    ingress {
        description = "allow eks to acesses toi rds postgres"
        from_port = 5432
        to_port = 5432
        protocol="tcp"
        security_groups = [aws_security_group.eks-sg]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags={
        Name="${var.project_name}-RDS-sg"
    }
  
}
  
