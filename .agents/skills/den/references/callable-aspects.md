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

## Local convention

When an argument selects extra child aspects from the parent namespace, call it `includes`:

```nix
(parent {
  includes = with parent; [
    child
  ];
})
```

So `includes` means: “include these additional child aspects with the parent”.

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

Host usage:

```nix
(parent {
  includes = with parent; [
    child
  ];
})
```

## Flow

1. Den calls `parent` with `{ includes = [ child ]; }`.
2. The callable functor appends the supplied list to the aspect's base `includes`.
3. Den resolves the parent and the selected aspects without inheriting that list as context.

Do not implement this with a parametric include that reads `includes` from context:
nested callable aspects can inherit the parent's list and recursively include themselves.
Keep normal host/user context resolution in Den's parametric entries.

The supplied list can also group related aspects, such as a service and its SOPS secret.
See `modules/den/aspects/dvalin+/default.nix`; the secret stays in the user's context.
Regression tests live in `flake.tests.callable` in `modules/den/lib.nix`.
