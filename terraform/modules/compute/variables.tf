# 🧩 modules/compute/variables.tf — TODO(student).
# Define the inputs THIS module needs. Ask: what must the caller supply, and
# what can be derived internally? Give required vars no default.
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID from the network module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the Load Balancer"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Private subnets for the Application EC2 instances"
  type        = list(string)
}

variable "app_instance_profile_name" {
  description = "IAM instance profile from the IAM module"
  type        = string
}