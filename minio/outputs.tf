# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

output "vault_backup_bucket_name" {
  description = "Name of the Vault backup bucket"
  value       = minio_s3_bucket.vault_backups.bucket
}

output "vault_backup_bucket_id" {
  description = "ID of the Vault backup bucket"
  value       = minio_s3_bucket.vault_backups.id
}

output "vault_backup_bucket_versioning_enabled" {
  description = "Whether versioning is enabled for the Vault backup bucket"
  value       = var.enable_versioning
}
