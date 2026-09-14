# 🧩 modules/network/variables.tf — TODO(student).
# Define the inputs THIS module needs. Ask: what must the caller supply, and
# what can be derived internally? Give required vars no default.
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.100.0/24", "10.0.200.0/24"]
}