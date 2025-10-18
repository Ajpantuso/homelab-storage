# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

# Default values - override these with environment variables or in a .env file
CONTAINER_ENGINE ?= docker

# Include local overrides if they exist
-include .env

help:
	@echo "Available targets:"
	@echo "  flux-apply             - Apply Flux configuration"
.PHONY: help

# Flux targets
flux-apply:
	kubectl apply -k flux --prune --all \
	--prune-allowlist=source.toolkit.fluxcd.io/v1/gitrepository \
	--prune-allowlist=source.toolkit.fluxcd.io/v1beta2/helmrepository \
	--prune-allowlist=helm.toolkit.fluxcd.io/v2beta2/helmrelease \
	--prune-allowlist=kustomize.toolkit.fluxcd.io/v1/kustomization
.PHONY: flux-apply

update-k0s-version:
	@VERSION=$$(curl -sSL https://api.github.com/repos/k0sproject/k0s/releases/latest | jq -r .name) && \
	yq -r ".k0s.version = \"$$VERSION\"" --indentless -iy config.yaml
.PHONY: update-k0s-version

init-directpv: update-csinodes initialize-drives
.PHONY: init-directpv

update-csinodes:
	@echo "Updating all CSINodes with DirectPV driver information..."
	@for node in $$(kubectl get csinode -o jsonpath='{.items[*].metadata.name}'); do \
		echo "Patching CSINode: $$node"; \
		kubectl get csinode $$node -o json | \
		jq '.spec.drivers |= (. // [] | map(select(.name != "directpv-min-io")) + [{"name": "directpv-min-io", "nodeID": "'$$node'", "topologyKeys": ["directpv.min.io/identity", "directpv.min.io/node", "directpv.min.io/rack", "directpv.min.io/region", "directpv.min.io/zone"]}])' | \
		kubectl apply -f - || echo "  Failed to patch $$node"; \
	done
	@echo "CSINode update complete"
.PHONY: update-csinodes

initialize-drives:
	kubectl directpv init --dangerous <(kubectl get directpvnode storage -ojson \
	| jq -r '{"version": "v1", "nodes": [{ "name": .metadata.name, "drives": [.status.devices[] | select(has("deniedReason") | not) | { "id": .id, "name": .name, "size": .size, "make": .make, select: "yes"}]}]}' \
	| yq -y)
.PHONY: initialize-drives

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
