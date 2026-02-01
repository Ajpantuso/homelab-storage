# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

{
  description = "Homelab Storage development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            coreutils
            findutils
            git
            gnumake
            kubectl
            kustomize
            podman
            pre-commit
            reuse
            tenv
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";

            # Check if 'storage' context exists, if not create it
            if ! kubectl config get-contexts | grep -q "storage"; then
              kubectl config set-cluster storage --server=https://storage.ajphome.com:6443 --insecure-skip-tls-verify=true
              kubectl config set-context storage --cluster=storage --user=ajpantuso@gmail.com
            fi

            # Test connectivity to the cluster
            if kubectl cluster-info --context=storage &>/dev/null; then
              kubectl config use-context storage
            else
              echo "Warning: Could not connect to storage cluster at https://storage.ajphome.com:6443"
            fi
          '';
        };
      });
}
