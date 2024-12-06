resource "aws_vpc" "eks_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      Name ="eks_vpc"
    }
}

resource "aws_subnet" "private_sub-1" {
    vpc_id = aws_vpc.eks_vpc.id
    #cidr_block = "10.0.3.0/24"
    cidr_block = var.private_sub_1_cidr
    availability_zone = "us-east-1a"
    tags = {
        Name = "private_sub-1a"
        #"kubernetes.io/role/internal-elb" = "1"   >> if LB required in private subnet too
        #"kubernetes.io/cluster/my-cluster" = "shared"  >> Version 2.1.1 or earlier of the AWS Load Balancer Controller requires this tag.
    }
    depends_on = [ aws_vpc.eks_vpc ]
}

resource "aws_subnet" "private_sub-2" {
  vpc_id = aws_vpc.eks_vpc.id
  #cidr_block = "10.0.4.0/24"
  cidr_block = var.private_sub_2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_sub-2b"
  }
  depends_on = [ aws_vpc.eks_vpc ]
}

resource "aws_subnet" "public_sub-1" {
    vpc_id = aws_vpc.eks_vpc.id
    #cidr_block = "10.0.1.0/24"
    cidr_block = var.public_sub_1_cidr
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "public_sub-1b"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Version 2.1.1 or earlier of the AWS Load Balancer Controller requires this tag. now it is optional
    }
    depends_on = [ aws_vpc.eks_vpc ]
}

resource "aws_subnet" "public_sub-2" {
    vpc_id = aws_vpc.eks_vpc.id
    #cidr_block = "10.0.2.0/24"
    cidr_block = var.public_sub_2_cidr
    availability_zone = "us-east-1c"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "public_sub-1c"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Version 2.1.1 or earlier of the AWS Load Balancer Controller requires this tag. now it is optional
    }
    depends_on = [ aws_vpc.eks_vpc ]
}

resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.eks_vpc.id
    tags = {
        Name = "eks-IGW"
    }
    depends_on = [ aws_vpc.eks_vpc ]
}  

/*  if you create nodes in private sub then needed to acces it publically for this nat required. 
resource "aws_eip" "eks-eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eks-eip.id 
  subnet_id = aws_subnet.public_sub.id
  tags = {
    Name = "eks-nat"
  }
}
*/

resource "aws_route_table" "pub_rtable" {
    vpc_id = aws_vpc.eks_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id =  aws_internet_gateway.IGW.id
    }
    tags = {
      Name = "pub_rtable"
    }
    depends_on = [ aws_vpc.eks_vpc ]
}

/*resource "aws_route_table" "pub_2_rtable" {
    vpc_id = aws_vpc.eks_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id =  aws_internet_gateway.IGW.id
    }
    tags = {
      Name = "pub_rtable-2"
    }
}
*/

resource "aws_route_table_association" "r_table_associate" {
    route_table_id = aws_route_table.pub_rtable.id
    subnet_id = aws_subnet.public_sub-1.id
    depends_on = [ aws_route_table.pub_rtable, aws_subnet.public_sub-1 ]
}

resource "aws_route_table_association" "pub2_r_table_associate" {
    route_table_id = aws_route_table.pub_rtable.id
    subnet_id = aws_subnet.public_sub-2.id
    depends_on = [ aws_route_table.pub_rtable, aws_subnet.public_sub-2 ]
}


resource "aws_security_group" "nlb_sg" {
  vpc_id = aws_vpc.eks_vpc.id
  name = "nlb-sg"
  ingress {
    description = "allow http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    description = "allow https"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  } 
  egress {
		description = "allow all outbound traffic"
		from_port = 0
		to_port = 0 
		protocol = -1 
		cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [ aws_vpc.eks_vpc ]
}


locals {
  vpc_depends = [ aws_vpc.eks_vpc, aws_subnet.private_sub-1, aws_subnet.private_sub-2, aws_subnet.public_sub-1, aws_subnet.public_sub-2, aws_internet_gateway.IGW,  ]
}