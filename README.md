<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/readme-file. Use nix run .#write-files to regenerate it. -->

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

## Available commands

- `boot` — Schedule configuration for next boot
- `build` — Build configuration for host
- `switch` — Apply configuration to host
- `vm` — Build and run host in an ephemeral VM

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

By default it reads `./recovery.key.age`. Override with:

```sh
SOPS_RECOVERY_KEY=/path/to/recovery.key.age nix develop .#sops-recovery
```
