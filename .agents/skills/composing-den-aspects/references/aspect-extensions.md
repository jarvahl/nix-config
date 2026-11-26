# Conditional aspect configuration

This repository does not use a reflective global aspect-extension scanner.
Conditional behavior belongs in the owning aspect's class module.

```nix
den.aspects.parent.hjem =
  { user, ... }:
  lib.mkIf (user.hasAspect den.aspects.child) {
    # Configuration enabled when child is present in the resolved user tree.
  };
```

Use `host.hasAspect` for `.nixos` configuration and `user.hasAspect` for
`.hjem` configuration. These lookups happen after Den resolves the aspect tree,
so generated aspects are visible.

`hasAspect` must not be used in `includes`: the include graph is what Den uses
to construct the tree, and reading the tree there creates a cycle.

Use `provides` only when configuration must be routed between entities. It is
not an aspect-discovery mechanism.
