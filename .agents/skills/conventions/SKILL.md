---
name: conventions
description: Apply this repository's structural conventions when editing Den/Nix configuration, especially aspects, provisions, policies, hosts, and includes.
---

# Repository conventions

Preserve the existing repository topology and ownership. Prefer the smallest change that matches neighboring files.

## File-level attribute order

Use this order:

1. `den.aspects.<name>`
2. `den.policies.<name>`
3. `den.schema.<type>.includes`
4. `den.default.<target>.extraModules`
5. `flake-file.inputs.<name>.url`

## Aspect attribute order

Inside `den.aspects.<name>`, use this order:

1. `provides` and `_`
2. application classes (`zsh`, `tmux`, `nvim`, ...)
3. user classes (`hjem`, `homeManager`)
4. system classes (`nixos`, `darwin`)
5. `user`
6. `includes`

## Den structure

- Put `provides` inside the aspect attrset, even for one provision.
- Prefer `den.aspects.host = { provides.user.nixos = { ...; }; };` over chained assignments.
- For host fragments, attach `lib.mkMerge` directly to `den.aspects.<host>`.
- Put `provides` merge blocks before other aspect settings.
- Keep `den.hosts.<system>.<host>` outside the aspect merge.
- Keep host-wide includes in the host `default.nix`.
- Keep service-specific includes beside the service aspect.
- Keep user-specific includes in `aspects/+provides/<user>/default.nix`.
- Treat host-wide catch-all routing such as `to-users` as a provision under the host aspect; matching files stay at host level.

## Hosts and guests

- Keep host-specific guest container configuration in the host `default.nix`.
- Put the guest aspect and its matching host relation together in one attrset, separate from the host base configuration.
- Attach `lib.mkMerge` at the file's top level.
