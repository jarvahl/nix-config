# Conditional aspect extensions

A conditional aspect extension is configuration owned by one aspect and enabled
when another aspect is present in the resolved tree.

The extension belongs to the class that owns the options:

```nix
lib.mkMerge [
  {
    den.aspects.parent = {
      hjem = { ... };
    };
  }
  {
    den.aspects.parent.hjem =
      { user, ... }:
      lib.mkIf (user.hasAspect den.aspects.feature) {
        ...
      };
  }
]
```

Use `host.hasAspect` for a `.nixos` extension and `user.hasAspect` for a
`.hjem` or other user-class extension. These lookups are evaluated against the
resolved tree, so composed aspects are visible.

Do not implement extension discovery with a global scan over `den.aspects`.
Do not use `hasAspect` while constructing `includes`, because the include graph
must be resolved before the tree can be inspected.

Use `provides` only when the extension must be routed to another entity. A
provider does not activate an aspect and does not replace an explicit include.
