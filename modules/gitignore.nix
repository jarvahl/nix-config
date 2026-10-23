{ inputs, ... }:
{
  flake-file.inputs.gitignore-file = {
    inputs = {
      flake-parts.follows = "flake-parts";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:jarvahl/gitignore-file";
  };

  imports = [ inputs.gitignore-file.flakeModules.default ];
}
