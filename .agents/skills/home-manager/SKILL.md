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

Use `+modules/den/aspects/nvim.nix` as the reference.

