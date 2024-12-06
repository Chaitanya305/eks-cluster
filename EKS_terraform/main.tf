terraform {
    required_providers{
        aws ={
            source = "hashicorp/aws"
            version = "5.38.0"
        }
        helm ={
          source = "hashicorp/helm"
          version = "2.12.1"
        }
    }
}

provider "aws" {
  region = "us-east-1"
}

/*provider "kubernetes" {
  config_path = "~/.kube/config"
}*/

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "vpc" {
  source = "./vpc"
  vpc_cidr = "10.0.0.0/16"
  private_sub_1_cidr = "10.0.3.0/24"
  private_sub_2_cidr = "10.0.2.0/24"
  public_sub_1_cidr = "10.0.1.0/24"
  public_sub_2_cidr = "10.0.4.0/24"
  cluster_name = "demo-eks_cluster"
}

module "eks" {
  source = "./EKS"
  cluster_name = "demo-eks-cluster"
  public_sub_1 = module.vpc.public_sub_1
  private_sub_1 = module.vpc.private_sub_1
  private_sub_2 = module.vpc.private_sub_2
  public_sub_2 = module.vpc.public_sub_2
  instance_types_for_worker_nodes = "t3.medium"
  depends_on = [ module.vpc ]
}


output "cluster_name" {
  value = module.eks.cluster_name
}

output "endpoint" {
  value = module.eks.eks_endpoint
}

output "cert_data" {
  value = module.eks.eks_cluster_cert_base64
}