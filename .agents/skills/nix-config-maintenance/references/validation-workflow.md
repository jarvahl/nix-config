# Validation workflow

1. Inspect neighboring modules and `git status`.
2. Preserve topology and ownership.
3. Inspect the diff for ordering, generated-file edits, and unrelated changes.
4. Run the narrowest relevant check/evaluation.
5. Recheck the diff and report limitations.

Before Nix operations, stage only new untracked files the flake must see:

```sh
git add path/to/new-file.nix
```

Tracked modifications need no staging. Never stage unrelated work.

For skill-only documentation changes, run the skill validator and link/path checks; Nix evaluation is unnecessary. Keep generated files generated and follow `Conventions.md` for commit messages.
