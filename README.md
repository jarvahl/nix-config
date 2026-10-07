# nix-config

## Dev shell

```sh
nix develop
```

Available tools:

- `age` — create and inspect age keys
- `just` — run repo tasks; see `just --list`
- `mdsh` — run markdown docs from `docs/`
- `sops` — edit and decrypt secrets

## Docs

Run executable docs with `mdsh`:

```sh
mdsh docs/sops/create-recovery-key.md
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
