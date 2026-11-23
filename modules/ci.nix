{
  config,
  inputs,
  lib,
  nixExperimentalFeatures,
  ...
}:
{
  flake-file.inputs.actions-nix = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks.follows = "git-hooks-nix";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:nialov/actions.nix";
  };

  flake-file.inputs.nix-unit = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/nix-unit";
  };

  flake.actions-nix.workflows.".github/workflows/check.yaml" = {
    jobs.check = {
      runs-on = "ubuntu-latest";
      steps = [
        { uses = "actions/checkout@v6"; }
        {
          uses = "cachix/install-nix-action@v31";
          "with".extra_nix_config =
            "experimental-features = ${lib.concatStringsSep " " nixExperimentalFeatures}";
        }
        {
          name = "Check flake";
          run = "nix flake check --print-build-logs";
        }
      ];
    };
    on = {
      pull_request = { };
      push = { };
      workflow_dispatch = { };
    };
    permissions.contents = "read";
  };

  # Keep system-independent helper tests in flake.tests; this module exposes them through checks.
  imports = [
    inputs.actions-nix.flakeModules.default
    inputs.nix-unit.modules.flake.default
  ];

  perSystem =
    systemArgs@{ pkgs, ... }:
    let
      rendered = pkgs.runCommand "rendered-workflows" { } ''
        mkdir -p "$out"
        cd "$out"
        ${lib.getExe systemArgs.config.packages.render-workflows} --no-prepend-git-root
      '';
    in
    {
      apps.ci = {
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "ci";
            runtimeInputs = [
              pkgs.act
              pkgs.gitMinimal
            ];
            text = ''
              cd "$(git rev-parse --show-toplevel)"
              ${lib.getExe systemArgs.config.packages.render-workflows}
              exec act "$@"
            '';
          }
        );
        type = "app";
      };

      files.file = lib.mapAttrs (path: _: {
        source = "${rendered}/${path}";
      }) config.flake.actions-nix.workflows;

      nix-unit = {
        # Den fetches pinned libraries outside the flake input graph.
        allowNetwork = true;
        inherit inputs;
      };
    };
}
