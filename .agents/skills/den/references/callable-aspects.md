# Callable aspects

## General rule

Den aspects can be called with an attrset:

```nix
(aspect { arg = value; })
```

That attrset becomes context for parametric entries inside the aspect, especially functions in `includes`.

## Local convention

When an argument selects extra child aspects from the parent namespace, call it `includes`:

```nix
(parent {
  includes = { child, ... }: [
    child
  ];
})
```

So `includes` means: “select additional child aspects from this parent namespace”.

## Pattern

```nix
den.aspects.parent = {
  includes = [
    ({ includes ? (_: [ ]), ... }: {
      includes = includes (builtins.removeAttrs den.aspects.parent [ "__functor" ]);
    })
  ];

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
  includes = { child, ... }: [
    child
  ];
})
```

## Flow

1. Den calls `parent` with `{ includes = ...; }`.
2. `parent` has a parametric include that receives that attrset.
3. It calls the selector with `den.aspects.parent`.
4. The selector returns child aspects to include.

Use this when child aspects only make sense with the parent.
