{ inputs, ... }:
{
  den.default.homeManager = {
    home.stateVersion = "26.11";
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
  };

  flake-file.inputs.home-manager = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/home-manager";
  };
}
