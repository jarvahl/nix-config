{ inputs, ... }:
{
  den.default.nixos = {
    hjem.extraModules = [ inputs.sops-nix.homeManagerModules.sops ];
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  flake-file.inputs.sops-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };
}
