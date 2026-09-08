---
name: nix
description: Validate and operate on this repository's Nix flake safely.
---

# Nix workflow

1. Inspect neighboring modules and `git status` before changing or evaluating Nix.
2. Before a Nix operation, stage only newly created, untracked files the flake must see:
   `git add path/to/new-file.nix`
3. Tracked modifications need no staging.
4. Never stage unrelated work.
5. Never edit generated files directly; change their source instead.
6. Inspect the diff for unrelated changes and structural mistakes.
7. Run the narrowest relevant evaluation or check.
8. Recheck the diff and report validation limitations.

For documentation-only changes, use the available skill and link/path checks; Nix evaluation is unnecessary.
