{ lib, ... }:
{
  den.default.nixos = {
    home-manager = {
      sharedModules = [
        { home.stateVersion = lib.mkDefault "25.11"; }
      ];
      useGlobalPkgs = true;
    };

  };

  flake-file.inputs.home-manager = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/home-manager";
  };

}
