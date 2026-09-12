## Rules

- **IMPORTANT!** Every `.nix` file under `modules/` is auto-imported by `inputs.import-tree ./modules` in `flake.nix`; each file **MUST** therefore be a valid flake-parts module! New files **MUST** be added to Git tracking with `git add` or marked with intent-to-add using `git add -N`, so `import-tree` can see them.
- **IMPORTANT!** NEVER make changes, commits, or pushes without confirmation! First propose, then wait for explicit acceptance, then implement or commit! Until explicit acceptance, end every response with: `> Changes have not been approved yet.`
- When splitting host or user aspect configuration into multiple files, each file MUST remain a valid auto-imported flake-parts module and MUST be named after the main application/aspect it configures, not a generic concern.

## Commit conventions

### `modules/den/aspects/<host>/+provides/<user>/`

commit: `<host>(<user>): <hostAspect file name> -> <short description>`

### `modules/den/aspects/<host>/`

commit: `<host>: <hostAspect file name> -> <short description>`

### `modules/den/aspects/`

commit: `<aspect name>: <short description>`
when `default.nix`: `<aspect name>: <short description>`

### `modules/`

commit: `<module name>: <short description>`

### `AGENTS.md`, `.pi/`, and skills

commit: `ai: <short description>`

### `packages/`

commit: `packages: <package name> -> <short description>`

### `<repository root>/` (catch-all)

commit: `flake: <short description>`
