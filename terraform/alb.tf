# alb.tf - UPDATED VERSION (Forward to default)
resource "aws_lb" "app_alb" {
    name                       = "${var.project_name}-quickcart-alb"
    internal                   = false
    load_balancer_type         = "application"
    security_groups            = [aws_security_group.alb_sg.id]
    subnets                    = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    enable_deletion_protection = false
    
    tags = {
        Name = "${var.project_name}-quickcart-alb"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.app_alb.arn
    port              = "80"
    protocol          = "HTTP"
    
    default_action {
        type             = "forward"  # CHANGED: Forward instead of fixed-response
        target_group_arn = aws_lb_target_group.tg_product.arn  # Forward to product service by default
    }
}

# Path Based Rules for ALB
resource "aws_lb_listener_rule" "rule_auth" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 1
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_auth.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/auth*"]
        }
    }
}

resource "aws_lb_listener_rule" "rule_product" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 2
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_product.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/products*"]
        }
    }
}

resource "aws_lb_listener_rule" "rule_cart" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 3
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_cart.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/cart*"]
        }
    }
}

resource "aws_lb_listener_rule" "rule_order" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 4
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_order.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/orders*"]
        }
    }
}

resource "aws_lb_listener_rule" "rule_payment" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 5
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_payment.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/payments*"]
        }
    }
}

resource "aws_lb_listener_rule" "rule_email" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 6
    
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_email.arn
    }
    
    condition {
        path_pattern {
            values = ["/api/email*"]
        }
    }
}