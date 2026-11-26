# Den aspect composition

## Conditional configuration

Put conditions in the class module that owns the configuration:

```nix
den.aspects.example.hjem =
  { user, ... }:
  lib.mkIf (user.hasAspect den.aspects.feature) {
    # Hjem configuration.
  };
```

For host configuration use `host.hasAspect` in `.nixos` modules.

## Providers

Use `provides.to-hosts.*` and `provides.to-users.*` for configuration that
must cross entity boundaries. Do not use providers to discover aspects.

## Resolved-tree access

For static references use `hasAspect`. For generated or metadata-driven cases,
inspect `host.aspects`, `user.aspects`, or `home.aspects` from inside a class
module. Do not enumerate `den.aspects` during module evaluation.

## Scope

- `.hjem` owns user/home configuration.
- `.nixos` owns host/system configuration.
- Keep independent features in separate top-level attrsets.
- Keep SOPS declarations beside the extension that consumes them.
- Keep attribute keys alphabetically sorted.
