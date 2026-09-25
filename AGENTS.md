## Rules

- **IMPORTANT!** Every `.nix` file under `modules/` is auto-imported by `inputs.import-tree ./modules` in `flake.nix`; each file **MUST** therefore be a valid flake-parts module. See [New-file tracking](#new-file-tracking).
- **IMPORTANT!** `modules/flakelight/default.nix` evaluates the repository root through Flakelight's `mkFlake` with `nixDir = ./_`. Flakelight automatically loads flat `modules/flakelight/_/packages/*.nix` wrappers, exposes them as flake `packages`/`apps` outputs for `nix run`, then reuses its default overlay as `pkgs.<package-name>`, with the overlaid `pkgs` provided via `perSystem`. Package wrappers **MUST** stay flat and named after the package, without extra category words such as `extension` or `skill`; supporting files may stay under the root `packages/` tree.

### New-file tracking

Only newly created files **MUST** be added to Git tracking with `git add` or marked with intent-to-add using `git add -N`; modified files do not need this. This is required so auto-importers such as `import-tree` can see new files.

- **IMPORTANT!** Approval is one-time and scoped to a single task and its explicitly approved scope. Before any new task or change outside that scope, propose the exact operation and wait for explicit approval again. Until approval is given, do not modify files, commit, or push, and end every response with: `> Changes have not been approved yet.`
- **IMPORTANT!** Plans are scoped to a single task. The latest approved plan is authoritative and MUST be preserved in full when updated: modify it by adding, removing, or revising specific points, but do not shorten, replace, or silently omit details. Any new task requires a new scoped plan and approval.
- **IMPORTANT!** If a proposed action differs from the user's request, explain the difference and get the user's agreement before taking it; do not make that decision autonomously.
- **IMPORTANT!** Before committing or pushing, first propose the exact operation (scope, commit message, and whether history or remote state changes) and wait for explicit approval; a request to "commit" or "push" means prepare that proposal, not execute it immediately.
- When splitting host or user aspect configuration into multiple files, each file MUST remain a valid auto-imported flake-parts module and MUST be named after the main application/aspect it configures, not a generic concern.

## Commit conventions

### `modules/den/aspects/<host>/+provides/<user>/`

commit: `<host>(<user>): <hostAspect name without extension> -> <short description>`

### `modules/den/aspects/<host>/`

commit: `<host>: <hostAspect name without extension> -> <short description>`

### `modules/den/aspects/`

commit: `<aspect name>: <short description>`
when `default.nix`: `<aspect name>: <short description>`

### `modules/`

commit: `<module name>: <short description>`

### `AGENTS.md`, `.pi/`, and skills

commit: `ai: <short description>`

### `nix.d/packages/`

commit: `packages: <package name> -> <short description>`

### `<repository root>/` (catch-all)

commit: `flake: <short description>`
