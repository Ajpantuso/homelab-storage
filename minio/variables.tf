# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

variable "minio_server" {
  description = "MinIO server endpoint (e.g., api.minio.ajphome.com:443)"
  type        = string
}

variable "minio_access_key" {
  description = "MinIO access key (username)"
  type        = string
  sensitive   = true
}

variable "minio_secret_key" {
  description = "MinIO secret key (password)"
  type        = string
  sensitive   = true
}

variable "minio_ssl" {
  description = "Whether to use SSL/TLS for MinIO connection"
  type        = bool
  default     = true
}

variable "vault_backup_bucket_name" {
  description = "Name of the MinIO bucket for Vault backups"
  type        = string
  default     = "vault-backups"
}

variable "enable_versioning" {
  description = "Enable versioning for the Vault backup bucket"
  type        = bool
  default     = true
}
