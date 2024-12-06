output "public_sub_1"{
    value = aws_subnet.public_sub-1.id
}

output "private_sub_1"{
  value = aws_subnet.private_sub-1.id
}

output "public_sub_2" {
  value = aws_subnet.public_sub-2.id
}

output "private_sub_2" {
  value = aws_subnet.private_sub-2.id
}

output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}