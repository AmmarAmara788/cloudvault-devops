# =============================================================================
# 🧩 modules/iam — least-privilege identities. TODO(student).
# =============================================================================
# QUESTIONS TO ANSWER IN CODE:
#   - The services need to read/write ONE S3 bucket. What is the LEAST-privilege
#     way to grant that? Scope actions AND the resource ARN — not "s3:*" on "*".
#   - What should you NEVER do? (hint: bake long-lived access keys into env vars
#     or images). What is the credential-free alternative for compute? (roles /
#     instance profiles; on a real cluster, per-pod roles.)
#   - Separate roles per concern: app role vs. backup role — do they need the same
#     permissions? (No.) Why does that separation matter?
#
# ACCEPTANCE CRITERIA:
#   done when: policies name specific actions + the specific bucket ARN, there are
#   no long-lived keys anywhere, and removing any one permission breaks exactly
#   one intended capability (proving it's minimal).
#
# TODO(student): implement roles, policies, and instance profiles here.
# 1. إنشاء الـ Role الخاص بخوادم التطبيق (يسمح لـ EC2 بتقمص هذا الدور)
resource "aws_iam_role" "app_role" {
  name = "cloudvault-app-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. سياسة الصلاحيات الأقل (Least Privilege) للـ S3
resource "aws_iam_policy" "app_s3_policy" {
  name        = "cloudvault-app-s3-policy-${var.environment}"
  description = "Allow app to read/write to its specific S3 bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # السماح بعرض محتويات الـ Bucket
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.storage_bucket_arn
      },
      {
        # السماح بالقراءة والكتابة والحذف للملفات (Objects) داخل الـ Bucket فقط
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.storage_bucket_arn}/*"
      }
    ]
  })
}

# 3. ربط السياسة بالدور
resource "aws_iam_role_policy_attachment" "app_s3_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}

# 4. إنشاء ملف التعريف (Instance Profile) لربطه لاحقاً بخوادم EC2
resource "aws_iam_instance_profile" "app_profile" {
  name = "cloudvault-app-profile-${var.environment}"
  role = aws_iam_role.app_role.name
}