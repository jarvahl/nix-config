---
name: "home-manager"
description: "Use when configuring Home Manager modules through Hjem or registering external homeModules; not for standalone Home Manager setups."
---

<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Home Manager modules in Hjem

This repository includes an adapter that allows Home Manager modules to be used by Hjem.

To integrate an external Home Manager module:

1. Add its flake input.
2. Register its `homeModules.default` in `den.default.nixos.hjem.extraModules`.
3. Configure its native Home Manager options inside the relevant `hjem` aspect.

Use `modules/den/aspects/nvim/default.nix` as the reference; upstream export names may differ.

## Routing

| Task | Read |
| --- | --- |
| Registering or configuring an external module | Use the steps above |
| Bridging missing Home Manager options to Hjem Rum | `references/compatibility.md` |


## References
- [Home Manager compatibility in Hjem](references/compatibility.md)
