---
name: "import-tree"
description: "Uses denful/import-tree to recursively import Nix modules or discover non-Nix assets in flake-based repositories. Use when configuring import-tree inputs, module trees, initFilter, match, leaves, or path mapping."
---

# import-tree

Use `import-tree` when a repository needs recursive path discovery or module imports.

## Core usage

The default call discovers Nix modules:

```nix
inputs.import-tree ./modules
```

By default it recursively finds `.nix` files and ignores paths containing `/_`.

## Non-Nix assets

Use `initFilter` to replace the default `.nix` filter, `match` for a full-path regular expression, and `leaves` to return paths instead of a module:

```nix
((inputs.import-tree.initFilter (_: true))
  .match ".*/SKILL\\.md")
  .leaves
  ./skills
```

Use `map` or a normal Nix `map` to transform discovered paths, for example:

```nix
map builtins.dirOf skillFiles
```

## Workflow

1. Check whether the target is a Nix module tree or a non-Nix asset tree.
2. Use the default call for `.nix` modules.
3. Use `initFilter`, `match`, and `leaves` for other files.
4. Test the resulting path list with `nix eval` before building or deploying.
