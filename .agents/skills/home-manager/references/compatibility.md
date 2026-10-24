<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Home Manager compatibility in Hjem

When an external module reads a Home Manager option implemented by Hjem Rum,
register an alias globally in `den.default.nixos.hjem.extraModules`:

```nix
den.default.nixos.hjem.extraModules = [
  ({ lib, ... }: {
    imports = [
      (lib.mkAliasOptionModule
        [ "programs" "git" "enable" ]
        [ "rum" "programs" "git" "enable" ]
      )
    ];
  })
];
```

Keep this adapter next to the program's aspect, not in each consuming application.
The alias is available globally; the program's aspect decides whether to enable it.
Do not add dummy options with fixed defaults when a real backend option exists.
Alias individual options with compatible types, not an entire option namespace.

For adapters that also merge configuration, preserve ordering and package selection.
See `modules/den/aspects/zsh.nix`: `lib.mkBefore` places bundle initialization
before the aliased `initContent`; package wiring remains conditional on enablement.
Keep host/user side effects, such as selecting a login shell, in explicit aspects.

Verify both an enabled and a disabled consumer, and evaluate configuration ordering
when the adapter merges initialization text. Run `nix flake check --no-build`.
