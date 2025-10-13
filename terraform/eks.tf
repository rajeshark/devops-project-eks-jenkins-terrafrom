module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = "1.27"

  vpc_id     = var.vpc_id
  subnet_ids = [var.private_subnet_1, var.private_subnet_2]

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  enable_cluster_creator_admin_permissions = true

  fargate_profiles = {
    backend_profile = {
      name = "backend-profile"
      selectors = [
        {
          namespace = "backend"
        }
      ]
    }
  }
}
