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

## Generated files

Run from this repository:

```sh
nix run .#write-files
```

This runs `write-flake` first (including lock updates and automatic
follows), then writes the configured files, including documentation,
agent instructions, skills, and GitHub workflows. Edit their Nix
declarations, not the generated files.

`nix run .#write-flake` only regenerates the flake and updates its lock.
After input changes, run `write-files` again so the remaining generators
use the updated inputs; each invocation uses its initial evaluation.
Stage new source files before evaluation and new generated files before
running `nix flake check`.

## CI

GitHub Actions runs `nix flake check` on pushes and pull requests.
Workflow definitions live in `modules/actions.nix`; `write-files`
generates their YAML and flake checks verify it is up to date.

Run checks locally without containers:

```sh
nix flake check
```

To regenerate workflow YAML and execute it locally with `act`:

```sh
nix run .#ci
nix run .#ci -- -j check
```

Arguments are forwarded to `act`; use `nix run .#ci -- --list` to list
jobs without executing them. Execution requires a working Docker API
socket (Docker or a compatible Podman socket). `act` may prompt for a
runner image and does not fully reproduce GitHub-hosted runners.
The CI command only regenerates workflows, not all repository files.

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

The shell requires Linux with a running systemd user manager. Each session
gets a private runtime directory, removed by systemd when its shell exits,
including after SIGKILL. Run Terranix commands inside this shell:

```sh
nix run .#terranix.plan
```

Terranix reuses the unlocked key and exports secrets from `terranix.sops.yaml`
to its command environment, with uppercase path segments joined by underscores.
