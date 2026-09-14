# 🧩 Root input variables — TODO(student).
# HINTS:
#   - What belongs here vs. inside a module? (region, project name, environment,
#     CIDR ranges, AZ count, instance sizes...)
#   - Which variables need sensible defaults, and which must be required?
#   - Never default a secret. Where should secrets actually come from?
variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}