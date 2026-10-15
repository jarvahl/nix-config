{ ... }:
{
  flake-file.inputs.zsh-nix = {
    inputs = {
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "git-hooks-nix";
      home-manager.follows = "hjem-hm-modules/home-manager";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:jarvahl/zsh.nix";
  };
}
