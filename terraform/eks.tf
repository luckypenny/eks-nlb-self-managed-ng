provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

locals {
  name            = "eks-dev-cluster"
  cluster_version = "1.21"
  region          = "ap-northeast-2"

  tags = {
    Name    = local.name
    TerraformManged = "True"
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# EKS Module
################################################################################

module "eks" {
#  source = "terraform-aws-modules/eks/aws"
  source = "./modules/eks"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version

#  cluster_addons = {
#    coredns = {
#      resolve_conflicts = "OVERWRITE"
#    }
#    kube-proxy = {}
#    vpc-cni = {
#      resolve_conflicts = "OVERWRITE"
#    }
#  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t3.small"
  }

  self_managed_node_groups = {
    apps = {
      name         = "apps_node_group"
      mix_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  tags = local.tags
}

## 인그레스 컨트롤러 어드미션 파드에서 해당 포트를 사용함.
resource "aws_security_group_rule" "webhook_admission_inbound" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "webhook_admission_outbound" {
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
}