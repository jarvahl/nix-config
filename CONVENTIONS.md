# Repository conventions

## Generated files

Edit the source declaration, not the generated file.

| Generated file | Source |
| --- | --- |
| `AGENTS.md` | `AGENTS.md.nix` |
| `README.md` | `README.md.nix` |
| `.sops.yaml` | `.sops.yaml.nix` |
| `.agents/skills/*` | `.agents/skills.nix` |

Local file generators are imported by `modules/files.nix`.

## Nix modules

- Keep attribute keys sorted alphabetically within each attribute set.
- Use `default.nix` for the main module of a module directory.
- Keep generated-file declarations close to their generated output.
- Stage newly created files before evaluating the flake.

## Terranix

Terranix modules live under:

```text
modules/+configurations/den/aspects/*/_terranix/
```

The directory is imported explicitly into the global Terranix configuration.

## Commits

Use:

```text
<aspect>: <title>
```

For example:

```text
sops: simplify breakglass unlock
```
