---
name: "nixos-deployment"
description: "Deploys NixOS configurations from this repository to local or remote hosts. Use for build, switch, boot, and deployment verification tasks; do not use for authoring Nix modules."
---

# NixOS deployment

Use this skill when building or deploying a NixOS host from this repository.

1. Read the reference for the deployment target.
2. Check the worktree before evaluating the flake.
3. Stage newly created source files before evaluation; do not stage generated or cache paths.
4. Use the repository's deployment command instead of invoking an equivalent command manually.
5. Verify that activation completed successfully.

## References

| Target | Reference |
| --- | --- |
| Local host | [references/local.md](references/local.md) |
