# Den aspect composition

## Separate independent extensions

When a module defines a base aspect and several optional extensions, keep each
extension in its own top-level attrset. Use `lib.mkMerge` to compose them:

```nix
{ lib, ... }:

lib.mkMerge [
  {
    den.aspects.example.hjem = {
      # Base user configuration.
    };
  }
  {
    den.aspects.example.feature-a.hjem = {
      # Optional feature A.
    };
  }
  {
    den.aspects.example.feature-b.nixos = {
      # Optional host feature B.
    };
  }
]
```

This keeps each extension independently discoverable and avoids one large
attribute set whose parts have unrelated activation conditions.

## Keep scopes explicit

Use the scope that owns the configuration:

```nix
den.aspects.example.hjem = {
  # Home Manager/Hjem configuration for a user.
};

den.aspects.example.nixos = {
  # NixOS configuration for a host.
};
```

If a user aspect needs to contribute configuration to its host, use
`provides.to-hosts.nixos`; see `user-to-host.md`.

## Avoid manual inclusion

If the aspect-extension policy discovers an extension automatically, do not
also add it manually to `includes`. Manual inclusion can duplicate or bypass
the intended activation condition.
