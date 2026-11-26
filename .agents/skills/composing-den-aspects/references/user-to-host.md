# Routing between users and hosts

Use `provides` when configuration belongs to one entity but must be applied to
another entity's class module.

## User aspect to host

A user aspect can contribute NixOS configuration to its host through
`provides.to-hosts.nixos`:

```nix
den.aspects.user-feature.provides.to-hosts.nixos =
  { user, ... }:
  {
    users.users.${user.userName}.someOption = true;
  };
```

The provider is evaluated in the user context and its result is routed to the
host's NixOS configuration.

## Host aspect to users

A host aspect can route configuration to users through a target user class:

```nix
den.aspects.host-feature.provides.to-users.hjem =
  { host, ... }:
  {
    files.".config/example".text = "...";
  };
```

Use the target class that owns the options. `to-users.hjem` is for Hjem options;
other target classes should be used for their corresponding schemas.

## Boundaries

- Use a local `.hjem`, `.nixos`, or `.user` class when the configuration is
  already owned by the current entity.
- Use `provides` only for cross-entity routing.
- Do not use providers to discover aspects or activate conditional extensions.
- Do not add conditional aspects to `includes` based on `hasAspect`.
