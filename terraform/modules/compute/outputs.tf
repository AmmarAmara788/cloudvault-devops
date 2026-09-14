# 🧩 modules/compute/outputs.tf — TODO(student).
# Export only what OTHER modules or the root need to consume from compute.
output "app_server_id" {
  description = "The ID of the Application EC2 instance"
  value       = aws_instance.app_server.id
}