# Den routing

Use for aspects, provisions, policies, and schema includes.

## Order

File: `aspects` → `policies` → `schema.*.includes` → `default.*.extraModules` → `flake-file.inputs`.

Aspect: `provides`/`_` → app classes → user classes → system classes → `user` → `includes`.

Keep `den.hosts.*` outside aspect merges. Put host-wide includes in host `default.nix`, service includes beside the service aspect, and user includes in `aspects/+provides/<user>/default.nix`.

## Shape

```nix
den.aspects.example = {
  provides.user = { hjem = { pkgs, ... }: {
    packages = [ pkgs.example ];
  }; };
  hjem = { ... }: { };
  nixos = { ... }: { };
  includes = [ den.aspects.shared ];
};
```

Use `provides` even for one provision. For fragments, attach `lib.mkMerge` to the aspect:

```nix
den.aspects.example = lib.mkMerge [
  { nixos = { ... }: { }; }
  { provides.user = { ... }; }
];
```

Use a policy for conditional/adapted inclusion; register it in the matching schema:

```nix
den.policies.example = { host, ... }:
  lib.optional (host.example.enable or false)
    (den.lib.policy.include den.aspects.example);
den.schema.host.includes = [ den.policies.example ];
```

Keep catch-all routes such as `to-users` as provisions of their owning aspect.
