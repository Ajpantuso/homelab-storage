<!--
SPDX-FileCopyrightText: 2025 NONE

SPDX-License-Identifier: Unlicense
-->

# MinIO Terraform Configuration

This directory contains Terraform configuration for managing MinIO resources using the [aminueza/minio](https://registry.terraform.io/providers/aminueza/minio/latest/docs) provider.

## Overview

The Terraform project currently manages:
- **Vault Backup Bucket**: A MinIO S3 bucket for storing Vault backups with optional versioning support

## Prerequisites

1. **Terraform**: Version 1.0 or later
2. **MinIO Server**: Running and accessible (deployed via Flux HelmRelease in this repository)
3. **MinIO Credentials**: Access key and secret key with appropriate permissions

## Getting Started

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your MinIO configuration:

```hcl
minio_server     = "api.minio.ajphome.com:443"
minio_access_key = "your-minio-access-key"
minio_secret_key = "your-minio-secret-key"
minio_ssl        = true

vault_backup_bucket_name = "vault-backups"
enable_versioning        = true
```

> **Note**: The `terraform.tfvars` file is gitignored to prevent credential leakage.

### 2. Initialize Terraform

Initialize the Terraform working directory and download the MinIO provider:

```bash
terraform init
```

### 3. Plan Changes

Review the planned changes before applying:

```bash
terraform plan
```

### 4. Apply Configuration

Create the MinIO resources:

```bash
terraform apply
```

## Configuration Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `minio_server` | MinIO server endpoint | string | - | yes |
| `minio_access_key` | MinIO access key (username) | string (sensitive) | - | yes |
| `minio_secret_key` | MinIO secret key (password) | string (sensitive) | - | yes |
| `minio_ssl` | Use SSL/TLS for connection | bool | `true` | no |
| `vault_backup_bucket_name` | Name of Vault backup bucket | string | `"vault-backups"` | no |
| `enable_versioning` | Enable bucket versioning | bool | `true` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `vault_backup_bucket_name` | Name of the Vault backup bucket |
| `vault_backup_bucket_id` | ID of the Vault backup bucket |
| `vault_backup_bucket_versioning_enabled` | Whether versioning is enabled |

## Resources Managed

### minio_s3_bucket.vault_backups
Creates a private S3 bucket for storing Vault backups.

### minio_s3_bucket_versioning.vault_backups
Configures bucket versioning for backup retention and recovery.

## MinIO Server Details

The MinIO server is deployed via Flux in the parent repository:
- **Namespace**: `minio`
- **API Endpoint**: `api.minio.ajphome.com` (via Traefik ingress)
- **Console Endpoint**: `minio.ajphome.com` (via Traefik ingress)
- **Storage**: 500Gi DirectPV persistent volume
- **Mode**: Standalone

See [flux/minio.helmrelease.yaml](../flux/minio.helmrelease.yaml) for full configuration.

## Future Enhancements

Potential additions to this Terraform project:
- IAM policies for bucket access control
- Additional buckets for other services
- Bucket lifecycle policies for automated cleanup
- Bucket notifications for event-driven workflows
- Server-side encryption configuration

## Troubleshooting

### Connection Issues
- Verify MinIO server is running: `kubectl get pods -n minio`
- Check ingress configuration: `kubectl get ingress -n minio`
- Ensure DNS resolution for `api.minio.ajphome.com`
- Verify SSL certificates if using HTTPS

### Authentication Errors
- Confirm credentials match the `minio-creds` secret in the cluster
- Check MinIO console for user permissions
- Ensure the user has `s3:*` or appropriate bucket permissions

### Provider Errors
- Update provider version: `terraform init -upgrade`
- Consult provider documentation: https://registry.terraform.io/providers/aminueza/minio/latest/docs
