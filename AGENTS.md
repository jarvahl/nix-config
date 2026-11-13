<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Project rules

- This flake is evaluated from the Git tree. After creating, moving, or renaming files that Nix must import, stage the new paths before `nix eval`, `nix flake check`, or `direnv reload` (`git add <path>`). Untracked files are invisible to flake evaluation.
- Do not stage generated/cache paths like `.direnv/`.
- Edit Nix declarations, not generated files. Run `nix run .#write-files` to regenerate the flake/lock, documentation, skills, and workflows; after input changes, run it again to use the updated inputs. Stage new generated files before checks. `nix run .#ci` regenerates workflows and runs `act`, not all file generators.
- Keep Nix attribute keys sorted alphabetically within each attribute set.
- Read `CONVENTIONS.md` when changing the repository structure or adding modules.
- `import-tree` loads modules recursively; adding a `default.nix` under `modules/**` is enough once the path is tracked by Git.
- When including Den aspects, prefer `with den.aspects; [ ... ]` for local aspect names, especially names with hyphens like `dynamic-island`. Avoid direct long references unless needed.
- When including Den batteries, use `with den.batteries; [ ... ]`; put batteries at the end of `includes` in a separate array, e.g. `(with den.aspects; [ ... ]) ++ (with den.batteries; [ ... ])`.
- Declare SOPS secrets and templates directly in the aspect extension that consumes them, using separate top-level attrsets for each extension. Keep host and user SOPS source configuration in their explicit `.sops` extensions.
- In modules containing `skills` or `agents` declarations, use a top-level `lib.mkMerge`; keep those declarations in the last attribute set.

## Commit rules

- English.
- Format: `<aspect>: <title>`.
