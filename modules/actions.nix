{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.actions-nix.workflows.".github/workflows/check.yaml" = {
    jobs.check = {
      runs-on = "ubuntu-latest";
      steps = [
        { uses = "actions/checkout@v6"; }
        {
          uses = "cachix/install-nix-action@v31";
          "with".extra_nix_config = "extra-experimental-features = pipe-operators";
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

  flake-file.inputs.actions-nix = {
    inputs = {
      flake-parts.follows = "flake-parts";
      git-hooks.follows = "git-hooks-nix";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:nialov/actions.nix";
  };

  imports = [ inputs.actions-nix.flakeModules.default ];

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
    };

  readme-file.sections = lib.mkOrder 260 [
    {
      title = "CI";
      text = ''
        GitHub Actions runs `nix flake check` on pushes and pull requests.
        Workflow definitions live in `modules/actions.nix`; `write-files`
        generates their YAML and flake checks verify it is up to date.

        Run checks locally without containers:

        ```sh
        nix flake check
        ```

        To regenerate workflow YAML and execute it locally with `act`:

        ```sh
        nix run .#ci
        nix run .#ci -- -j check
        ```

        Arguments are forwarded to `act`; use `nix run .#ci -- --list` to list
        jobs without executing them. Execution requires a working Docker API
        socket (Docker or a compatible Podman socket). `act` may prompt for a
        runner image and does not fully reproduce GitHub-hosted runners.
        The CI command only regenerates workflows, not all repository files.
      '';
    }
  ];
}
