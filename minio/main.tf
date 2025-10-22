# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

terraform {
  required_version = ">= 1.0"

  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 2.0"
    }
  }
}

provider "minio" {
  minio_server   = var.minio_server
  minio_user     = var.minio_access_key
  minio_password = var.minio_secret_key
  minio_ssl      = var.minio_ssl
}

# MinIO bucket for Vault backups
resource "minio_s3_bucket" "vault_backups" {
  bucket = var.vault_backup_bucket_name
  acl    = "private"
}

# Optional: Configure bucket versioning for backup retention
resource "minio_s3_bucket_versioning" "vault_backups" {
  bucket = minio_s3_bucket.vault_backups.bucket

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}
