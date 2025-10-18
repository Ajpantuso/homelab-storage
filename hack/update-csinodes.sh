#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

echo "Updating all CSINodes with DirectPV driver information..."

for node in $(kubectl get csinode -o jsonpath='{.items[*].metadata.name}'); do
  echo "Patching CSINode: $node"
  kubectl get csinode "$node" -o json \
    | jq '.spec.drivers |= (. // []
        | map(select(.name != "directpv-min-io")) + [
          {
            "name": "directpv-min-io",
            "nodeID": "'"$node"'",
            "topologyKeys": [
              "directpv.min.io/identity",
              "directpv.min.io/node",
              "directpv.min.io/rack",
              "directpv.min.io/region",
              "directpv.min.io/zone"
            ]
          }
        ])' \
    | kubectl apply -f - || echo "  Failed to patch $node"
done

echo "CSINode update complete"
