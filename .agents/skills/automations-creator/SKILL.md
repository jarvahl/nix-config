---
name: automations-creator
description: Create and maintain host-specific Den/Nix automations routed through HJEM and systemd --user for any configured host or user. Use when adding or changing automation modules, agent operational instructions, host-level automation discovery, or automation timers in the nix-config repository.
---

# Automations Creator

Use this skill for host-specific automation design and implementation. Load and follow `nix-config-maintenance` for Den topology, aspect/provision routing, attribute ordering, staging, formatting, and Nix validation.

## Automation contract

Keep the runtime path:

```text
host aspect → provides.<user> → hjem → systemd --user
```

Keep each automation local to its host and user:

```text
modules/den/+hosts/<system>/<host>/aspects/+provides/<user>/+automations/
└── <name>.nix
```

Use one `pkgs.writeShellApplication` when the automation is a linear stdin/stdout command chain. Define its systemd service and timer directly beside it. Use `OnCalendar` for a clock time or `OnUnitActiveSec` for an interval, and set `Persistent = true` for periodic runs.

Do not add a runtime, CLI, retry system, scheduler, database, or custom flake output unless explicitly requested. Do not add a `Justfile` solely to wrap systemd commands.

## Agent operations

Operate automations through their user units:

```sh
systemctl --user start automation-example.service
journalctl --user -fu automation-example.service
systemctl --user status automation-example.service automation-example.timer
```

Use the existing `nix-config-maintenance` validation workflow. Evaluate the host's `ExecStart`, and build/run the existing host configuration when operational verification is requested.
