{ inputs, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem =
    { config, pkgs, ... }:
    {
      pre-commit = {
        check.enable = true;
        settings.hooks = {
          treefmt.enable = true;
        };
      };

      devShells.default = pkgs.mkShell {
        name = "nix-zsh-shell";
        inherit (config.pre-commit) shellHook;
      };
    };

  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
