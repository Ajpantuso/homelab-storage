#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

echo "Initializing DirectPV drives..."

kubectl directpv init --dangerous <(kubectl get directpvnodes -ojson \
  | jq -r '
    {
      "version": "v1",
      "nodes": [ .items[] | {
        "name": .metadata.name,
        "drives": [ .status.devices[] | select(has("deniedReason") | not) | {
          "id": .id,
          "name": .name,
          "size": .size,
          "make": .make,
          select: "yes"
        }]
      }]
    }' \
  | yq -y)

echo "DirectPV drives initialized successfully"
