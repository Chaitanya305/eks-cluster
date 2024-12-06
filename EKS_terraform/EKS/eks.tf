/*locals {
  iam_role_depends = [ aws_iam_role.eks_acces_role, aws_iam_role.node_group_acces_role, aws_iam_policy_attachment.eks_policy_attach, aws_iam_policy_attachment.node_gp_CNI_policy_attach, aws_iam_policy_attachment.node_gp-worker-node-policy, aws_iam_policy_attachment.AmazonEC2ContainerRegistryReadOnly ]
}*/

locals {
  iam_role_depends = [ aws_iam_role.eks_acces_role, aws_iam_role.node_group_acces_role, aws_iam_policy_attachment.eks_policy_attach, aws_iam_policy_attachment.node_gp_policy_attach ]
}

resource "aws_iam_role" "eks_acces_role" {
    name = "eks_role"
    description = "this role is to acces other aws services form eks"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        },
    ]

    })
}


resource "aws_iam_role" "node_group_acces_role" {
    name = "node_gp_role"
    description = "this role is to acces other aws services from woker nodes in node group."
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        },
    ]

    })
}


resource "aws_iam_policy_attachment" "eks_policy_attach" {
  name = "eks-policy-attach"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles = [aws_iam_role.eks_acces_role.name]
}


/*resource "aws_iam_policy_attachment" "node_gp-worker-node-policy"{
  name = "node_gp-worker-node-policy"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"   # to connet ec2 to EKS cluster
  roles = [aws_iam_role.node_group_acces_role.name]
}

resource "aws_iam_policy_attachment" "node_gp_CNI_policy_attach" {
  name = "node_gp_CNI_policy_attac"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"   # the permissions it requires to modify the IP address configuration on your EKS worker nodes.
  roles = [aws_iam_role.node_group_acces_role.name]
}

resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  name = "AmazonEC2ContainerRegistryReadOnly"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  
  roles = [aws_iam_role.node_group_acces_role.name]
}*/

variable "node_gp_policy" {
  type = list(string)
  default = [ "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" ]
}

resource "aws_iam_policy_attachment" "node_gp_policy_attach" {
  name = "node_gp_policy_attach"
  for_each = toset(var.node_gp_policy)
  policy_arn = each.value
  roles = [aws_iam_role.node_group_acces_role.name]
}


resource "aws_eks_cluster" "eks-cluster" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks_acces_role.arn
  version = "1.30"
  vpc_config {
    subnet_ids = [var.public_sub_1, var.private_sub_1, var.public_sub_2, var.private_sub_2]
    #endpoint_private_access = true
   }
  #depends_on = [ aws_iam_policy_attachment.eks_policy_attach, aws_iam_role.eks_acces_role, aws_vpc.dev_digital_back_office_vpc, aws_iam_role.node_group_acces_role ]
  depends_on = [ local.iam_role_depends ]
}

resource "aws_eks_node_group" "eks-ng" {
  node_group_name = "pub-node-gp"
  cluster_name = aws_eks_cluster.eks-cluster.name
  node_role_arn = aws_iam_role.node_group_acces_role.arn
  subnet_ids = [var.public_sub_1, var.public_sub_2]
  scaling_config {
    desired_size = 1
    min_size = 1
    max_size = 2
  }
  instance_types = [var.instance_types_for_worker_nodes]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  #depends_on = [ aws_eks_cluster.eks-cluster, aws_iam_role.node_group_acces_role ]
  depends_on = [ aws_eks_cluster.eks-cluster, local.iam_role_depends ]
}

locals {
  eks_depends = [ aws_eks_cluster.eks-cluster, aws_eks_node_group.eks-ng]
}
