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
	@echo "  setup-lvm              - Setup LVM volume group for TopoLVM (requires DEVICE=/dev/sdX)"
	@echo "  verify-lvm             - Verify LVM setup for TopoLVM"
	@echo "  topolvm-status         - Show TopoLVM deployment status"
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

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply

# TopoLVM LVM setup targets
setup-lvm:
	@echo "Setting up LVM for TopoLVM..."
	@if [ -z "$(DEVICE)" ]; then \
		echo "ERROR: DEVICE is required"; \
		echo "Usage: make setup-lvm DEVICE=/dev/sdb [VG_NAME=homelab-vg]"; \
		exit 1; \
	fi
	sudo "$(PROJECT_ROOT)/hack/setup-lvm.sh" --device "$(DEVICE)" --vg-name "$${VG_NAME:-homelab-vg}"
.PHONY: setup-lvm

verify-lvm:
	@"$(PROJECT_ROOT)/hack/verify-lvm.sh" "$${VG_NAME:-homelab-vg}"
.PHONY: verify-lvm

topolvm-status:
	@echo "TopoLVM Resources:"
	@kubectl get all -n topolvm-system 2>/dev/null || echo "  No resources found (not deployed yet)"
	@echo ""
	@echo "TopoLVM Nodes:"
	@kubectl get topolvmnodes.topolvm.io -A 2>/dev/null || echo "  No TopoLVMNode resources found"
	@echo ""
	@echo "StorageClass:"
	@kubectl get storageclass topolvm-provisioner 2>/dev/null || echo "  topolvm-provisioner not found"
.PHONY: topolvm-status
