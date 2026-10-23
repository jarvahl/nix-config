{ inputs, ... }:
{
  flake-file.inputs.readme-file = {
    url = "github:jarvahl/readme-file";
    inputs = {
      files.follows = "files";
      flake-parts.follows = "flake-parts";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  imports = [ inputs.readme-file.flakeModules.default ];
}
