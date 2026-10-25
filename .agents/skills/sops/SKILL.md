---
name: "sops"
description: "Use when managing SOPS secrets, age keys, or recovery in this repository; not for general encryption."
---

<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# SOPS

Use this skill for SOPS maintenance in this repo.

## Routing

| Task | Read |
| --- | --- |
| Declaring secrets, choosing host/user context, or wiring a consumer | `references/secrets.md` |
| Creating or rotating the passphrase-encrypted recovery identity | `references/create-recovery-key.md` |
| Unsure | Start with `references/secrets.md` |

Keep this file light. Detailed runbooks live in `references/`.


## References
- [Create recovery identity](references/create-recovery-key.md)
- [Declare and consume SOPS secrets](references/secrets.md)
