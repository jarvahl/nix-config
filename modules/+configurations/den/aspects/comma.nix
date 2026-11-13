{ inputs, ... }:

{
  flake-file.inputs.nix-index-database = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/nix-index-database";
  };

  den.aspects.comma.nixos.programs.nix-index-database.comma.enable = true;

  den.default.nixos.imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];
}
