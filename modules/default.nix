{ inputs, lib, ... }:
let
  core = {
    flake-file.inputs = {
      flake-file.url = "github:denful/flake-file";
      flake-parts.url = "github:hercules-ci/flake-parts";
      nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    };

    readme-file.title = "nix-config";
    systems = inputs.nixpkgs.lib.systems.flakeExposed;
  };

  integrations = [
    {
      # comma
      flake-file.inputs.nix-index-database = {
        inputs.nixpkgs.follows = "nixpkgs";
        url = "github:nix-community/nix-index-database";
      };
    }
    {
      # nvim
      flake-file.inputs.nvf = {
        inputs.nixpkgs.follows = "nixpkgs";
        url = "github:notashelf/nvf";
      };
    }
    {
      # pi
      flake-file.inputs = {
        pi.url = "github:lukasl-dev/pi.nix";
        wrappers.url = "github:lassulus/wrappers";
      };
    }
    {
      # zsh
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
  ];
in
{
  imports = with inputs.flake-file.flakeModules; [
    auto-follow
    default
    import-tree
  ];
}
// lib.mkMerge ([ core ] ++ integrations)
