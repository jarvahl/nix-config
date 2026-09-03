# Global Instructions

For Den/Nix configuration work, use `.agents/skills/nix-config-maintenance/SKILL.md`.
For Quickshell OSD work, use `.agents/skills/quickshell-osd/SKILL.md`.

- Before a Nix operation, run `git add <path>` only for newly created, untracked files that the flake needs to see. Modified files that are already tracked are visible to Nix flakes and do not need to be staged again after each change.

Commit message conventions are documented in [`Conventions.md`](Conventions.md).
