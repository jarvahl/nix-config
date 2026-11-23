{ inputs, ... }:
{
  flake-file.inputs.git-hooks-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:cachix/git-hooks.nix";
  };

  flake-file.inputs.treefmt-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:numtide/treefmt-nix";
  };

  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { ... }: {
    pre-commit = {
      check.enable = true;
      settings.hooks = {
        deadnix = {
          enable = true;
          settings.edit = true;
        };
        treefmt.enable = true;
      };
    };

    treefmt = {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
      settings.global.excludes = [
        "**/*.sops.yaml"
      ];
    };
  };
}
