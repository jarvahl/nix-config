{
  config,
  inputs,
  lib,
  ...
}:
let
  hostArg = [
    {
      name = "host";
      default = "`hostname`";
    }
  ];

  rebuildRecipes =
    lib.genAttrs
      [
        "boot"
        "build"
        "switch"
      ]
      (action: {
        description =
          {
            boot = "Schedule configuration for next boot";
            build = "Build configuration for host";
            switch = "Apply configuration to host";
          }
          .${action};
        attributes.no-exit-message = true;
        args = hostArg;
        text =
          {
            boot = ''
              #!/usr/bin/env bash
              set -euo pipefail

              nixos-rebuild boot \
                  --flake ".#{{host}}" \
                  --elevate=sudo \
                  -L \
                  --accept-flake-config
            '';
            build = ''
              #!/usr/bin/env bash
              set -euo pipefail

              nixos-rebuild build \
                  --flake ".#{{host}}" \
                  -L \
                  --show-trace \
                  --accept-flake-config
            '';
            switch = ''
              #!/usr/bin/env bash
              set -euo pipefail

              printf '\033[0;32m------------------------\033[0m\n'
              printf '\033[1;32m\uf444 switch \033[0;32m%s\033[0m\n' "{{host}}"
              printf '\033[0;32m------------------------\033[0m\n'

              nixos-rebuild switch \
                  --flake ".#{{host}}" \
                  --elevate=sudo \
                  -L \
                  --show-trace \
                  --accept-flake-config

              printf '\n'
            '';
          }
          .${action};
      });

  recipeDescription =
    recipe:
    if lib.isAttrs recipe then
      let
        value = recipe.description or null;
      in
      if value == null then "" else value
    else
      "";

  describedRecipes = lib.filter (name: recipeDescription config.just.recipes.${name} != "") (
    builtins.attrNames config.just.recipes
  );
in
{
  readme.sections = lib.mkOrder 200 [
    {
      title = "Available commands";
      text = lib.concatMapStringsSep "\n" (
        name:
        let
          description = recipeDescription config.just.recipes.${name};
        in
        "- `${name}` — ${description}"
      ) describedRecipes;
    }
  ];

  flake-file.inputs.just-file = {
    url = "github:jarvahl/just-file";
    inputs = {
      files.follows = "files";
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "git-hooks-nix";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  imports = [ inputs.just-file.flakeModules.default ];

  just.recipes = rebuildRecipes // {
    default = "just --list";

    vm = {
      description = "Build and run host in an ephemeral VM";
      attributes.no-exit-message = true;
      args = hostArg;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        export NIX_DISK_IMAGE="$tmp/disk.qcow2"

        nixos-rebuild build-vm \
            --flake ".#{{host}}" \
            -L \
            --show-trace \
            --accept-flake-config

        "./result/bin/run-{{host}}-vm"
      '';
    };
  };
}
