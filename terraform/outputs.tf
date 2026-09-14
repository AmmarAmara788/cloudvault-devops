# 🧩 Root outputs — TODO(student).
# HINTS:
#   - What does a grader / the next tool need to see? (the public endpoint URL,
#     the bucket name, the load balancer DNS name...)
#   - Do NOT output secrets.
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs for public subnets"
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "List of IDs for app subnets"
  value       = module.network.app_subnet_ids
}

output "data_subnet_ids" {
  description = "List of IDs for isolated data subnets"
  value       = module.network.data_subnet_ids
}

output "storage_bucket_id" {
  description = "The globally unique identifier (name) of the S3 bucket"
  value       = module.storage.bucket_id
}

output "storage_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.storage.bucket_arn
}
output "app_instance_profile_name" {
  description = "The name of the IAM instance profile for the app"
  value       = module.iam.app_instance_profile_name
}

output "app_server_id" {
  description = "The ID of the Application EC2 instance"
  value       = module.compute.app_server_id
}