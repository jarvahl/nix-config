{ inputs, ... }:
{
  flake-file.inputs.nix-unit = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:nix-community/nix-unit";
  };

  imports = [ inputs.nix-unit.modules.flake.default ];

  perSystem.nix-unit = {
    # Den fetches pinned libraries outside the flake input graph.
    allowNetwork = true;
    inherit inputs;
  };
}
