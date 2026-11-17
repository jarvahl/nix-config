# User-to-host configuration

Use this pattern when an aspect included by a user must modify the
corresponding host's NixOS configuration:

```nix
den.aspects.user-feature.provides.to-hosts.nixos =
  { user, ... }:
  {
    users.users.${user.userName}.someOption = true;
  };
```

Use the appropriate scope:

- `.hjem` for user/home configuration;
- `.nixos` for host/system-owned configuration;
- `.provides.to-hosts.nixos` when a user aspect contributes to its host.

The provider transfers the user aspect's NixOS fragment to the host
configuration. Do not manually add aspect extensions to `includes` when
`aspect-extensions.nix` activates them automatically.
