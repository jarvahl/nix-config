{ inputs, ... }:
{
  den.default.nixos = {
    imports = [ inputs.hjem-home-manager.nixosModules.default ];

    hjem.extraModules = [
      inputs.hjem-rum.hjemModules.default
    ];
  };

  flake-file.inputs = {
    hjem.url = "github:feel-co/hjem";
    hjem-home-manager = {
      url = "git+ssh://git@github.com/jarvahl/hjem-home-manager.git";
      inputs = {
        hjem.follows = "hjem";
        nixpkgs.follows = "nixpkgs";
      };
    };
    hjem-rum.url = "github:snugnug/hjem-rum";
  };
}
