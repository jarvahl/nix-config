{ inputs, ... }:
{
  den.aspects.herdr.hjem.programs.herdr = {
    enable = true;
  };

  den.default.nixos.hjem.extraModules = [
    inputs.herdnix.homeManagerModules.default
  ];

  flake-file.inputs.herdnix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Ra77a3l3-jar/herdnix";
  };
}
