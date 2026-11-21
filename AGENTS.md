# Project rules

- This flake is evaluated from the Git tree. After creating, moving, or renaming files that Nix must import, stage the new paths before `nix eval`, `nix flake check`, or `direnv reload` (`git add <path>`). Untracked files are invisible to flake evaluation.
- For NixOS deployment tasks, use the `nixos-deployment` skill and select the appropriate deployment reference.
- Do not stage generated/cache paths like `.direnv/`.
- Keep Nix attribute keys sorted alphabetically within each attribute set.
- Read `CONVENTIONS.md` when changing the repository structure or adding modules.
- Use `import-tree` for recursive Nix imports and asset discovery in this repository; consult its skill for filtering and layout details.
- For non-Nix assets, use `import-tree.initFilter` with `.match` or a path predicate and `.leaves` to obtain discovered paths.
- When including Den aspects, prefer `with den.aspects; [ ... ]` for local aspect names, especially names with hyphens like `dynamic-island`. Avoid direct long references unless needed.
- When including Den batteries, use `with den.batteries; [ ... ]`; put batteries at the end of `includes` in a separate array, e.g. `(with den.aspects; [ ... ]) ++ (with den.batteries; [ ... ])`.
- Declare SOPS secrets and templates directly in the aspect extension that consumes them, using separate top-level attrsets for each extension. Keep host and user SOPS source configuration in their explicit `.sops` extensions.
- In modules containing `skills` or `agents` declarations, use a top-level `lib.mkMerge`; keep those declarations in the last attribute set.

## Commit rules

- English.
- Format: `<aspect>: <title>`.
