---
name: herdr-plugin-packaing
description: Package Herdr plugins declaratively in this Nix repository.
---

# Packaging Herdr plugins

- Put the derivation in `packages/<plugin-name>/package.nix`; Flakelight/import-tree discovers it automatically.
- Pin GitHub sources by commit and SRI hash. Do not install plugins imperatively with `herdr plugin install`.
- Use `stdenvNoCC` for shell/config plugins. Install the plugin manifest and scripts into `$out`; make shipped scripts executable.
- Keep the package self-contained: preserve `herdr-plugin.toml` and every file referenced through `$HERDR_PLUGIN_ROOT`.
- Validate with `nix build .#nixosConfigurations.<host>.pkgs.<plugin-name>` and `nix fmt -- --fail-on-change`.
