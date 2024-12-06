resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.eks-cluster.name}"
  }
  #depends_on = [aws_eks_cluster.eks-cluster]
  depends_on = [ local.eks_depends, local.iam_role_depends ]
}
