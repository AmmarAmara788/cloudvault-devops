# 🧩 modules/storage/variables.tf — TODO(student).
# Define the inputs THIS module needs. Ask: what must the caller supply, and
# what can be derived internally? Give required vars no default.
# =============================================================================
# modules/storage/variables.tf
# Input variables for configuring the S3 storage bucket.
# =============================================================================

variable "bucket_prefix" {
  description = "Prefix used for the S3 bucket name to maintain uniqueness"
  type        = string
  default     = "cloudvault-storage"
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}