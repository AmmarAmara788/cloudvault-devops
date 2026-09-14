# 🧩 modules/storage/outputs.tf — TODO(student).
# Export only what OTHER modules or the root need to consume from storage.

# =============================================================================
# modules/storage/outputs.tf
# Exports resource IDs and ARNs needed by IAM policies and Compute services.
# =============================================================================

output "bucket_id" {
  description = "The globally unique identifier (name) of the S3 bucket"
  value       = aws_s3_bucket.vault.id
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the S3 bucket"
  value       = aws_s3_bucket.vault.arn
}