# 🧩 modules/iam/variables.tf — TODO(student).
# Define the inputs THIS module needs. Ask: what must the caller supply, and
# what can be derived internally? Give required vars no default.
variable "environment" {
  description = "Deployment environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "storage_bucket_arn" {
  description = "The ARN of the S3 bucket to grant access to"
  type        = string
}