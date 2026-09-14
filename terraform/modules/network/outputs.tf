# 🧩 modules/network/outputs.tf — TODO(student).
# Export only what OTHER modules or the root need to consume from network.
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for public subnets"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "List of IDs for app subnets (egress-only)"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "List of IDs for isolated data subnets"
  value       = aws_subnet.data[*].id
}