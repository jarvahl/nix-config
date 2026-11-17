---
name: "composing-den-aspects"
description: "Composes Den aspects and aspect extensions in this NixOS repository. Use when adding host, user, or aspect-specific extensions, or changing aspect includes."
---

# Composing Den aspects

Before modifying aspect composition, read:

`modules/+configurations/den/policies/aspect-extensions.nix`

Aspect extensions are discovered automatically by that policy. Do not manually
add an extension to `includes` when the policy already handles it.

## Composition rules

- Keep independent aspect extensions in separate top-level attrsets.
- Use `lib.mkMerge [ { ... } { ... } ]` when one module declares multiple independent extensions.
- Keep host and user extensions separate.
- Use `.hjem` for user/home configuration and `.nixos` for host/system configuration.
- Use `provides.to-hosts.nixos` when a user aspect must contribute configuration to its host.
- Preserve alphabetically sorted attribute keys.
- Inspect an existing module with similar composition before introducing a new pattern.

## References

| Topic | Reference | Read when |
| --- | --- | --- |
| User-to-host configuration | `references/user-to-host.md` | An aspect included by a user must modify the host's NixOS configuration. |
