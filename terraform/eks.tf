# Fargate Pod Execution IAM Role
resource "aws_iam_role" "fargate_pod_execution" {
  name = "${var.project_name}-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution.name
}

# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = "1.27"
  
  # Network Configuration
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Fargate Profiles
  fargate_profiles = {
    backend_profile = {
      name = "backend-profile"
      pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn
      selectors = [
        {
          namespace = "backend"
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = var.project_name
  }
}