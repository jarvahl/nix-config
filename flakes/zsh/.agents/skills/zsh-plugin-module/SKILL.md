---
name: zsh-plugin-module
description: Add or update zsh plugin modules in this repo under modules/+wrapper/modules/plugins, following the local Nix module and zsh.startPlugins/zsh.optPlugins structure.
---

# Zsh Plugin Module

Use this skill when adding a plugin to this repository's wrapper module tree.

## Local Structure

- Put plugin modules under `modules/+wrapper/modules/plugins/`, grouped by domain:
  - `autosuggestions/`
  - `completion/`
  - `editing/`
  - `history/`
  - `integrations/`
  - `syntax-highlighting/`
- Dendritic module discovery is used, so a tracked new `.nix` file in this tree is normally enough for registration.
- Core plugin option types are defined in `modules/+wrapper/modules/plugins.nix`.

## Plugin Shape

Prefer the existing two-module pattern:

```nix
{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.<feature.path>.enable = lib.mkEnableOption "<plugin-name>";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.<feature.path>.enable {
        zsh.optPlugins.<plugin-id> = {
          package = pkgs.<package>;
          source = "<path-inside-package>";
        };
      };
    })
  ];
}
```

Use `zsh.startPlugins` for plugins needed during startup ordering or prompt/highlighting behavior. Use `zsh.optPlugins` for plugins loaded through the idle loader.

## Plugin Fields

Each plugin attr supports:

- `package`: Nix package containing plugin files.
- `source`: one script path inside `package`.
- `sources`: ordered script paths when multiple files must be sourced.
- `init`: zsh commands run after sourcing plugin files.
- `after`: plugin ids that must load first.

Examples in this repo:

- single source: `autosuggestions/zsh-autosuggestions.nix`
- multiple sources: `integrations/git.nix`
- fetched package with init: `completion/fzf-tab.nix`
- flake input plus ordering: `syntax-highlighting/patina.nix`

## Verification

After adding a plugin, search for similar modules first and keep naming consistent. Do not add checks for a simple plugin registration unless explicitly requested. For new files, run `git add <path>` before relying on flake evaluation or checks.
