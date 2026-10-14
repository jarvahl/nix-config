---
name: "sops"
description: "SOPS operational runbooks for this repo, including recovery keys and bootstrap secrets."
---

# SOPS

Use this skill for SOPS maintenance in this repo.

## Routing

| Task | Read |
| --- | --- |
| Creating or rotating the passphrase-encrypted recovery age identity | `references/create-recovery-key.md` |
| Unsure | Start with `references/create-recovery-key.md` |

Keep this file light. Detailed runbooks live in `references/`.


## References
- [Create SOPS recovery key](references/create-recovery-key.md)
