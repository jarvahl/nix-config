# Aspect extensions

The aspect-extension policy treats a child aspect as an extension when its
name is also an existing aspect name and its value is an attribute set.

Conceptually, an extension is declared like this:

```nix
den.aspects.parent.child = {
  hjem = {
    # Configuration that belongs to the child integration.
  };
};
```

The policy includes the child extension when both conditions are true:

1. the parent aspect is active;
2. the extension aspect is active.

This allows a feature to be enabled by composing its aspects rather than by
adding a special case to the parent aspect.

## Practical rules

- Name the child according to the feature it provides.
- Keep the extension in a separate top-level attrset.
- Put user configuration under `.hjem` and host configuration under `.nixos`.
- Do not manually add an automatically discovered extension to `includes`.
- Read the policy implementation before changing its activation behavior.
