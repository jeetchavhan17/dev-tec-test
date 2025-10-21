output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" {
  value = aws_subnet.public[*].id
}
output "default_sg_id" {
  value = aws_security_group.default.id
}

