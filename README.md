<!--
SPDX-FileCopyrightText: 2025 NONE

SPDX-License-Identifier: Unlicense
-->

# Homelab Storage

Kubernetes-based storage infrastructure using K0s, Flux, and TopoLVM.

## Quick Start

1. Setup environment:
   ```bash
   nix develop
   ```

2. Setup storage (one-time):
   ```bash
   make setup-lvm DEVICE=/dev/sda
   make setup-lvm DEVICE=/dev/sdb
   make verify-lvm
   ```

3. Deploy Flux:
   ```bash
   make flux-apply
   ```

See [CLAUDE.md](./CLAUDE.md) for detailed documentation.

## References

- [TopoLVM Documentation](https://github.com/topolvm/topolvm)
