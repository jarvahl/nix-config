---
name: pipelines-creator
description: Create and maintain host-specific Den/Nix pipelines routed through HJEM and systemd --user for any configured host or user. Use when adding or changing pipeline modules, agent operational instructions, host-level pipeline discovery, or pipeline timers in the nix-config repository.
---

# Pipelines Creator

Use this skill only for pipeline-specific design and implementation. Load and follow `nix-config-maintenance` for Den topology, aspect/provision routing, attribute ordering, staging, formatting, and Nix validation; do not duplicate those rules here.

## Pipeline contract

Keep the runtime path:

```text
host aspect → provides.<user> → hjem → systemd --user
```

Keep the shared implementation private:

- `modules/default.nix` declares `flake-file.inputs.dag`.
- `modules/pipeline.nix` defines the `pipeline` and `trigger` helpers and passes them through `_module.args`.
- Do not expose `den.lib.pipeline`, custom flake pipeline outputs, package outputs, or a `$PATH` command.

Put a one-file pipeline directly in the pipeline directory:

```text
modules/den/+hosts/<system>/<host>/aspects/+provides/<user>/+pipelines/
└── <name>.nix
```

When a pipeline needs multiple files, give it a directory instead:

```text
modules/den/+hosts/<system>/<host>/aspects/+provides/<user>/+pipelines/<name>/
├── pipeline.nix
└── <supporting files>
```

Keep a pipeline-local `Justfile` only when a human-facing repository command is explicitly useful.

## Pipeline implementation

Use the private helper from the pipeline module:

```nix
{ pipeline, trigger, ... }:
{
  den.aspects.<host>.provides.<user>.hjem = { pkgs, ... }:
    let
      package = pipeline {
        name = "pipeline-example";
        nodes = { ... };
        inherit pkgs;
      };
    in
    trigger {
      name = "pipeline-example";
      inherit package;
      at = "08:00";
      # Use `each = "15min"` instead of `at` for an interval.
    };
}
```

The helper uses `denful/dag` to order nodes by `needs`, creates one `pkgs.writeShellApplication`, preserves `passthru.nodes`, and joins node executables with ordinary pipes under `set -euo pipefail`.

Keep nodes inline and local to the pipeline. Use stdin/stdout/stderr only; do not add a runtime, CLI, retry system, scheduler, database, or fan-in/fan-out model to the MVP.

Prefix service and timer names with `pipeline-`. For periodic pipelines, define the timer beside the service and use `Persistent = true` where missed runs should be replayed.

## Agent operations

When operating a pipeline for the agent, use its systemd units directly:

```sh
systemctl --user start pipeline-example.service
journalctl --user -fu pipeline-example.service
systemctl --user status pipeline-example.service pipeline-example.timer
```

Do not add a `Justfile` solely to wrap these commands. Add one only when the pipeline needs a stable human-facing interface.

Use the existing `nix-config-maintenance` validation workflow. For pipeline-specific checks, evaluate the host's `ExecStart`, and build/run the existing host configuration when operational verification is requested.
