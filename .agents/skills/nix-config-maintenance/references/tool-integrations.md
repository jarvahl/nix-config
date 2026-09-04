# Tool integrations

Use the smallest layer that fits:

- package only: `hjem.packages`;
- shell setup: add `zsh.initConfig`;
- declarative settings/reusable integration: `rum.programs.<tool>`;
- custom/conditional module: `hjem.extraModules` or custom `rum` module.

Keep package and setup in one aspect:

```nix
den.aspects.example = {
  zsh = { lib, pkgs, ... }: {
    initConfig = ''eval "$(${lib.getExe pkgs.example} init zsh)"'';
  };
  hjem = { pkgs, ... }: { packages = [ pkgs.example ]; };
};
```

Keep non-reused plugin fetch/build inline. Declare consumed inputs beside the aspect; use `nixpkgs.follows = "nixpkgs"` where applicable. Never edit generated `flake.nix` directly.

For host-specific Neovim, group LSP presets, server overrides, and language declarations in role-named `lib.mkMerge` fragments. Reuse existing aspects through `includes` instead of duplicating setup.
