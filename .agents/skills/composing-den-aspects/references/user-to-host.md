# User-to-host configuration

Use this pattern when an aspect is included by a user aspect but must modify the corresponding host's NixOS configuration:

```nix
den.aspects.<aspect>.provides.to-hosts.nixos = ...
```

Example:

```nix
den.aspects.heeler.provides.to-hosts.nixos =
  { user, ... }:
  {
    users.users.${user.userName}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 ... heeler"
    ];
  };
```

Use:

- `.hjem` for user/home configuration,
- `.provides.to-hosts.nixos` for user-to-host configuration,
- `.nixos` for host/system-owned configuration.

The `provides.to-hosts.nixos` provider transfers the user aspect's NixOS fragment to the host configuration. Do not manually add aspect extensions to `includes` when `aspect-extensions.nix` activates them automatically.

A `+` suffix in an aspect name denotes a host aspect, such as `zero+` or `cargo+`; it is not a generic fragment-directory convention.
