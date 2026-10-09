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
      url = "github:jarvahl/hjem-home-manager";
      inputs = {
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        hjem.follows = "hjem";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    hjem-rum.url = "github:snugnug/hjem-rum";
  };
}
