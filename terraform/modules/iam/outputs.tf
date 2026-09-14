# 🧩 modules/iam/outputs.tf — TODO(student).
# Export only what OTHER modules or the root need to consume from iam.
output "app_instance_profile_name" {
  description = "The name of the IAM instance profile to attach to EC2 instances"
  value       = aws_iam_instance_profile.app_profile.name
}