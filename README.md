# nix-config

## Dev shell

```sh
nix develop
```

Available tools:

- `age` — create and inspect age keys
- `just` — run repo tasks; see `just --list`
- `mdsh` — run markdown runbooks from agent skill references
- `sops` — edit and decrypt secrets

## Runbooks

Run executable runbooks with `mdsh`, for example:

```sh
mdsh .agents/skills/sops/references/create-recovery-key.md
```

## SOPS recovery shell

Unlock an encrypted recovery age identity for SOPS:

```sh
nix develop .#sops-recovery
```

By default it reads `./recovery.agekey.age`. Override with:

```sh
SOPS_RECOVERY_KEY=/path/to/recovery.agekey.age nix develop .#sops-recovery
```
