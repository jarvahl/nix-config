{ inputs, ... }:
{
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    readme-file = {
      url = "github:jarvahl/readme-file";
      inputs = {
        files.follows = "files";
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  imports = with inputs.flake-file.flakeModules; [
    auto-follow
    default
    import-tree
    inputs.readme-file.flakeModules.default
    ./readme.nix
  ];

  systems = inputs.nixpkgs.lib.systems.flakeExposed;
}
