<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Callable aspects

## General rule

Den aspects can be called with an attrset:

```nix
(aspect { arg = value; })
```

Native Den calls pass that attrset as context for parametric entries.
The repository's `den.lib.callable` helper instead takes an additional aspect;
it does not forward the argument as descendant context.

## Pattern

```nix
den.aspects.parent = den.lib.callable {
  # base aspect config...
};
```

Child feature in another file:

```nix
den.aspects.parent.child.nixos = { ... }: {
  # child feature config
};
```

Pass a single child aspect directly:

```nix
(parent parent.child)
```

To group several aspects, pass an anonymous aspect with `includes`:

```nix
(parent {
  includes = with parent; [
    child
  ];
})
```

The functor appends `[ extraAspect ]` to the parent's base `includes`, preserving both.
The argument may also define `nixos` or `hjem` configuration directly.
Den resolves it as an aspect, not as call parameters.

Do not implement this with a parametric include that reads `includes` from context:
nested callable aspects can inherit the parent's list and recursively include themselves.
Keep normal host/user context resolution in Den's parametric entries.

An anonymous aspect can group related aspects, such as a service and its SOPS secret.
`sops.secret params aspect` already accepts a consuming aspect; it returns a plain
aspect and needs no additional callable wrapper.
See `modules/den/aspects/dvalin+/default.nix`; the secret stays in the user's context.
Regression tests live in `flake.tests.callable` in `modules/den/lib.nix`.
