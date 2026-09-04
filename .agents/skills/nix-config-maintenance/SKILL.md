---
name: nix-config-maintenance
description: Maintain this repository's Den/Nix configuration. Use when adding, moving, refactoring, or reviewing aspects, policies, providers, host modules, user modules, guest containers, or Nix tool integrations.
---

# Nix configuration maintenance

These rules describe this repository's conventions. Preserve the existing structure when changing files.

## Attribute order

At file level, use this order:

1. `den.aspects.<name>`
2. `den.policies.<name>`
3. `den.schema.<type>.includes`
4. `den.default.<target>.extraModules`
5. `flake-file.inputs.<name>.url`

Inside `den.aspects.<name>`, use this order:

1. `provides` and `_`
2. application classes (`zsh`, `tmux`, `nvim`, ...)
3. user classes (`hjem`, `homeManager`)
4. system classes (`nixos`, `darwin`)
5. `user`
6. `includes`

## Den structure

- Put `provides` inside the aspect attrset, even for one provision.
- Prefer `den.aspects.host = { provides.user.nixos = { ...; }; };` over chained assignments such as `den.aspects.host.provides.user.nixos = ...`.
- For host fragments, attach `lib.mkMerge` directly to `den.aspects.<host>`.
- Put `provides` merge blocks before other aspect settings.
- Keep `den.hosts.<system>.<host>` outside the aspect merge.
- Keep host-wide includes in the host `default.nix`, service-specific includes beside the service aspect, and user-specific includes in `aspects/+provides/<user>/default.nix`.
- Treat host-wide catch-all routing such as `to-users` as a provision under the host aspect; matching files stay at host level.

Details: [`references/den-routing.md`](references/den-routing.md).

## Hosts and guests

- Keep host-specific guest container configuration in the host `default.nix`, not a sibling `guests.nix` or guest-named file.
- Put the guest aspect and its matching host relation (for example `nixosContainers` or `den.hosts.<system>.<host>.guests.<guest>`) together in one attrset, separate from the host base configuration.
- Attach `lib.mkMerge` at the file's top level.

## Tools and plugins

- Keep plugin package fetches/builds inline with the plugin declaration unless the derivation is intentionally reused.
- For simple console tools, prefer `hjem.packages` plus `zsh.initConfig`; add custom `rum.programs.<tool>` or `hjem.extraModules` only for reusable, conditional, or non-trivial integration.
- For host-specific Neovim tooling, group related LSP presets, server overrides, and language declarations with `lib.mkMerge` by host role, such as `frontend` and `backend`.

Details: [`references/tool-integrations.md`](references/tool-integrations.md).

## Validation

Inspect the diff and run the narrowest relevant Nix evaluation or check after structural changes. Before any Nix operation, stage only newly created, untracked files that the flake must see; tracked modifications are already visible to flakes.

Workflow: [`references/validation-workflow.md`](references/validation-workflow.md).
