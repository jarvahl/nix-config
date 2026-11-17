---
name: "composing-den-aspects"
description: "Composes Den aspects and aspect extensions in this NixOS repository. Use when adding host, user, or aspect-specific extensions, or changing aspect includes."
---

# Composing Den aspects

Before modifying aspect composition, read:

`modules/+configurations/den/policies/aspect-extensions.nix`

Aspect extensions are discovered automatically by that policy. Do not manually
add an extension to `includes` when the policy already handles it.

Keep host and user extensions separate, use separate top-level extensions, and
preserve the repository's sorted attribute keys.

## References

| Topic | Reference | Read when |
| --- | --- | --- |
| User-to-host configuration | `references/user-to-host.md` | An aspect included by a user must modify the host's NixOS configuration. |
