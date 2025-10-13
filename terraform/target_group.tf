#target group creation
resource "aws_lb_target_group" "tg_auth" {
    name="${var.project_name}-tg-auth"
    target_type = "ip"
    protocol = "HTTP"
    port=5005
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-auth"
    }
}
resource "aws_lb_target_group" "tg_product" {
    name="${var.project_name}-tg-product"
    target_type = "ip"
    protocol = "HTTP"
    port=5001
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-product"
    }
}
resource "aws_lb_target_group" "tg_cart" {
    name="${var.project_name}-tg-cart"
    target_type = "ip"
    protocol = "HTTP"
    port=5002
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-cart"
    }
}
resource "aws_lb_target_group" "tg_order" {
    name="${var.project_name}-tg-order"
    target_type = "ip"
    protocol = "HTTP"
    port=5003
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-order"
    }
}
resource "aws_lb_target_group" "tg_payment" {
    name="${var.project_name}-tg-payment"
    target_type = "ip"
    protocol = "HTTP"
    port=5004
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-payment"
    }
}
resource "aws_lb_target_group" "tg_email" {
    name="${var.project_name}-tg-email"
    target_type = "ip"
    protocol = "HTTP"
    port=5006
    vpc_id = aws_vpc.my-vpc-1.id
    health_check {
      path="/health"
      protocol="HTTP"
      interval=30
      timeout=5
      healthy_threshold =2
      unhealthy_threshold = 2
      matcher = "200"
    }
    tags={
        Name="${project_name}-tf-email"
    }
}