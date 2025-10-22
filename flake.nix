# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

{
  description = "Homelab Storage development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-kubectl-directpv.url = "github:Ajpantuso/nix-kubectl-directpv";
  };

  outputs = { self, nixpkgs, flake-utils, nix-kubectl-directpv }:
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
            nix-kubectl-directpv.packages.${system}.default
            podman
            pre-commit
            reuse
            tenv
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";

            kubectl config use-context storage
          '';
        };
      });
}
