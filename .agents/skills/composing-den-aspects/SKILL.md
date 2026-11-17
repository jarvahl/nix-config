---
name: "composing-den-aspects"
description: "Composes Den aspects and aspect extensions in this NixOS repository. Use when adding host, user, or aspect-specific extensions, or changing aspect includes."
---

# Composing Den aspects

Before modifying aspect composition, read:

`modules/+configurations/den/policies/aspect-extensions.nix`

Aspect extensions are discovered automatically by that policy. Do not manually
add an extension to `includes` when the policy already handles it.

## Workflow

1. Read `modules/+configurations/den/policies/aspect-extensions.nix`.
2. Inspect an existing module with similar composition before introducing a new pattern.
3. Keep independent aspect extensions in separate top-level attrsets.
4. Use `.hjem` for user/home configuration and `.nixos` for host/system configuration.
5. Preserve alphabetically sorted attribute keys.

## References

| Topic | Reference | Read when |
| --- | --- | --- |
| Aspect composition | `references/composition-patterns.md` | A module contains multiple related aspects or extensions. |
| Aspect activation | `references/aspect-extensions.md` | An extension should activate when a parent aspect is enabled. |
| User-to-host configuration | `references/user-to-host.md` | An aspect included by a user must modify the host's NixOS configuration. |
