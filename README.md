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
nix develop .#sops
```

By default it unlocks the recovery identity from `./breakglass.age`. Override with:

```sh
SOPS_KEYS_FILE=/path/to/breakglass.age nix develop .#sops
```

`nix develop .#terranix` unlocks the same recovery identity on entry, too.
Both shells require Linux with a running systemd user manager. Each session
gets a private runtime directory, removed by systemd when its shell exits,
including after SIGKILL. Terranix commands reuse the shell's unlocked key.
