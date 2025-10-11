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

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
