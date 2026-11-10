{
  config,
  lib,
  mkReadmeSection,
  ...
}:
let
  rebuildActions = {
    boot = {
      description = "Schedule configuration for next boot";
      flags = [ "--elevate=sudo" ];
    };
    build = {
      description = "Build configuration for host";
      flags = [ "--show-trace" ];
    };
    switch = {
      after = ''
        printf '\n'
      '';
      before = ''
        printf '\033[0;32m------------------------\033[0m\n'
        printf '\033[1;32m\uf444 switch \033[0;32m%s\033[0m\n' "{{host}}"
        printf '\033[0;32m------------------------\033[0m\n'
      '';
      description = "Apply configuration to host";
      flags = [
        "--elevate=sudo"
        "--show-trace"
      ];
    };
    vm = {
      action = "build-vm";
      after = ''
        "./result/bin/run-{{host}}-vm"
      '';
      before = ''
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        export NIX_DISK_IMAGE="$tmp/disk.qcow2"
      '';
      description = "Build and run host in an ephemeral VM";
      flags = [ "--show-trace" ];
    };
  };

  rebuildRecipes = lib.mapAttrs (name: recipe: {
    args = [
      {
        default = "`hostname`";
        name = "host";
      }
    ];
    attributes.no-exit-message = true;
    description = recipe.description;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      ${recipe.before or ""}
      nixos-rebuild ${recipe.action or name} \
          --flake ".#{{host}}" \
          -L \
          ${lib.concatStringsSep " " recipe.flags} \
          --accept-flake-config

      ${recipe.after or ""}
    '';
  }) rebuildActions;

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
  readme."Available commands" = mkReadmeSection 200 (
    lib.concatMapStringsSep "\n" (
      name:
      let
        description = recipeDescription config.just.recipes.${name};
      in
      "- `${name}` — ${description}"
    ) describedRecipes
  );

  just.recipes = rebuildRecipes // {
    default = "just --list";
  };
}
