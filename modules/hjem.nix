{ inputs, ... }:
{
  den.default.nixos = {
    hjem.extraModules = [ inputs.hjem-rum.hjemModules.default ];
    imports = [ inputs.hjem-hm-modules.nixosModules.default ];

  };

  flake-file.inputs = {
    hjem = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:feel-co/hjem";
    };
    hjem-hm-modules = {
      inputs = {
        hjem.follows = "hjem";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:jarvahl/hjem-hm-modules";
    };
    hjem-rum.url = "github:snugnug/hjem-rum";
  };

}
