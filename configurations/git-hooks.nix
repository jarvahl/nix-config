{ inputs, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem = { ... }: {
    pre-commit = {
      check.enable = true;
      settings.hooks = {
        treefmt.enable = true;
        deadnix = {
          enable = true;
          settings.edit = true;
        };
      };
    };
  };

  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
