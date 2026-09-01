{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = { ... }: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs.nixpkgs-fmt.enable = true;
      programs.prettier.enable = true;
      programs.shfmt.enable = true;
    };
  };

  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
