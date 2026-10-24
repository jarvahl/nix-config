<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Callable aspects

## General rule

Den aspects can be called with an attrset:

```nix
(aspect { arg = value; })
```

Native Den calls pass that attrset as context for parametric entries.
The repository's `den.lib.callable` helper instead consumes `includes` at call time;
it does not forward call arguments as descendant context.

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

Use `includes` for the list of additional aspects selected at the call site:

```nix
(parent {
  includes = with parent; [
    child
  ];
})
```

The functor appends this list to the parent's base `includes`, preserving both.
Den resolves the resulting tree without passing that list as descendant context.

Do not implement this with a parametric include that reads `includes` from context:
nested callable aspects can inherit the parent's list and recursively include themselves.
Keep normal host/user context resolution in Den's parametric entries.

The supplied list can also group related aspects, such as a service and its SOPS secret.
See `modules/den/aspects/dvalin+/default.nix`; the secret stays in the user's context.
Regression tests live in `flake.tests.callable` in `modules/den/lib.nix`.
