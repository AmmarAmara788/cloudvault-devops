# =============================================================================
# 🧩 modules/storage — the S3 bucket (and any managed DB). TODO(student).
# =============================================================================
# QUESTIONS TO ANSWER IN CODE:
#   - The bucket must be PRIVATE. What settings enforce that (public access block,
#     ownership, default encryption)? How do downloads still work? (presigned URLs
#     — the app already does this; you provide a private bucket.)
#   - Should object versioning be on? What does it buy you for the backup story?
#   - If you provision managed Postgres instead of containers: which subnet tier?
#     Which security group may reach it? (coordinate with compute + network)
#
# ACCEPTANCE CRITERIA:
#   done when: the bucket is private AND the app can still upload/download via
#   presigned URLs AND no credentials are committed to Git.
#
# TODO(student): implement resource "aws_s3_bucket" (+ hardening) and optional DB here.
# 1. إنشاء الـ S3 Bucket الأساسي
# =============================================================================
# modules/storage/main.tf
# Provisions a hardened, private S3 bucket adhering to AWS security best practices.
# =============================================================================

# 1. Primary S3 Bucket Definition
resource "aws_s3_bucket" "vault" {
  bucket_prefix = "${var.bucket_prefix}-${var.environment}-"
  
  # force_destroy allows deleting non-empty buckets during local/dev testing
  force_destroy = true

  tags = {
    Name        = "${var.bucket_prefix}-${var.environment}"
    Environment = var.environment
  }
}

# 2. Enable Object Versioning for Backup and Accidental Deletion Protection
resource "aws_s3_bucket_versioning" "vault" {
  bucket = aws_s3_bucket.vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enforce Server-Side Encryption (SSE-S3 / AES256) by Default
resource "aws_s3_bucket_server_side_encryption_configuration" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Enforce Bucket Ownership Controls (Disables legacy S3 ACLs)
resource "aws_s3_bucket_ownership_controls" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 5. Restrict All Public Access (Hardening)
resource "aws_s3_bucket_public_access_block" "vault" {
  bucket = aws_s3_bucket.vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}