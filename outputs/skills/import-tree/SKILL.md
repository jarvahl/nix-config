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

By default it recursively finds eligible `.nix` files and ignores paths containing `/_`. Files whose names start with `_` are not imported. A file does not need to be named `default.nix`.

## File and directory layout

Use a flat file for a module that consists of one file:

```text
modules/foo.nix
```

When a module is split into a directory, use `default.nix` as its entry point:

```text
modules/foo/
├── default.nix
├── options.nix
└── config.nix
```

A directory containing only `default.nix` can be flattened back to `foo.nix`.

## Filtering and outputs

Use `.filter` to narrow the existing filter. Use `initFilter` to replace the
default `.nix` filter. The `.match` argument is a regular expression matched
against the full path.

Calling a configured tree normally returns a Nix module. Use `.leaves` when
the consumer needs the discovered paths instead:

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
