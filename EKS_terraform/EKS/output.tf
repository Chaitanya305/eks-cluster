output "cluster_name" {
  value = aws_eks_cluster.eks-cluster.name
}

output "eks_endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

output "eks_cluster_cert_base64" {
  value = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}