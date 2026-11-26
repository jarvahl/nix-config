# Den composition concepts

## Aspect

An aspect is a reusable piece of configuration and composition metadata. It can
be included by a host, user, or another aspect. An aspect may expose one or
more class modules and may route configuration with `provides`.

An aspect is not the same thing as a class. The aspect identifies a feature;
the class identifies the configuration scope in which that feature is applied.

## Class module

A class module is configuration for a specific scope. Common classes in this
repository are:

- `hjem` — user/home configuration consumed by Hjem;
- `nixos` — host/system configuration consumed by NixOS;
- `user` — user-account configuration;
- other classes supplied by Den or an integration.

A class body is forwarded to that class's target options. Therefore a `.hjem`
body contains Hjem options directly; it must not contain another `hjem` wrapper.

```nix
den.aspects.example.hjem = {
  files.".config/example".text = "...";
};
```

## Resolved aspect tree

Den first resolves aspect inclusion and composition, then evaluates class
modules. The resolved tree contains the aspects that actually apply to the
current host or user, including aspects introduced through composition.

Use `hasAspect` inside class modules when the reference is known statically:

```nix
den.aspects.example.hjem =
  { user, ... }:
  lib.mkIf (user.hasAspect den.aspects.feature) {
    ...
  };
```

For dynamic or metadata-based logic, inspect `user.aspects`, `host.aspects`, or
`home.aspects` inside the relevant class module.

## Includes

`includes` constructs the aspect tree. It is evaluated before the resolved tree
exists, so `hasAspect` must not be used to decide an `includes` list. Doing so
creates a dependency cycle.

Use explicit includes for composition, not for activating conditional class
configuration.

## Providers

`provides` routes configuration from one entity to another. Examples include a
user aspect contributing NixOS configuration to its host, or a host aspect
contributing Hjem configuration to users.

```nix
den.aspects.example.provides.to-hosts.nixos =
  { user, ... }:
  {
    users.users.${user.userName}.someOption = true;
  };
```

Providers are routing declarations, not aspect-discovery or extension-
activation mechanisms.

## Conditional configuration

Put conditional configuration in the class that owns the options. Keep the
base configuration together and use a separate top-level `mkMerge` fragment
for a conditional extension:

```nix
lib.mkMerge [
  {
    den.aspects.example = {
      hjem = { ... };
    };
  }
  {
    den.aspects.example.hjem =
      { user, ... }:
      lib.mkIf (user.hasAspect den.aspects.feature) {
        ...
      };
  }
]
```

Do not use a global scanner over `den.aspects` to discover extensions.
