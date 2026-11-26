# Repository validation

Use this checklist after changing Den configuration in this repository.

## Generated files

Regenerate repository outputs before reviewing the diff:

```bash
nix run .#write-files
git status --short
```

Review generated changes. Keep them when they reflect the current source tree;
do not manually edit generated files.

## Git-tree evaluation

This flake evaluates from the Git tree. Stage new, moved, or renamed Nix source
files before running evaluation:

```bash
git add <path>
```

Do not stage `.direnv`, build outputs, or other generated/cache directories.

## Checks

Run formatting checks and a targeted build:

```bash
git diff --check
just build <host>
```

Do not run a system switch unless the user explicitly requests it.
