# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    actions-nix = {
      url = "github:nialov/actions.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    den = {
      url = "github:denful/den";
    };
    files = {
      url = "github:mightyiam/files";
      inputs = {
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    flake-file = {
      url = "github:denful/flake-file";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem-hm-modules = {
      url = "github:jarvahl/hjem-hm-modules";
      inputs = {
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        hjem.follows = "hjem";
        home-manager.follows = "home-manager";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
      };
    };
    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs = {
        hjem.follows = "hjem";
        nixpkgs.follows = "nixpkgs";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:denful/import-tree";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs = {
        bun2nix.inputs.treefmt-nix.follows = "treefmt-nix";
        bun2nix-x86_64-darwin.inputs = {
          nixpkgs.follows = "nixpkgs";
          treefmt-nix.follows = "treefmt-nix";
        };
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    sops-file = {
      url = "github:jarvahl/sops-file";
      inputs = {
        files.follows = "files";
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terranix = {
      url = "github:terranix/terranix";
      inputs = {
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zsh-nix = {
      url = "github:jarvahl/zsh.nix";
      inputs = {
        flake-file.follows = "flake-file";
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        home-manager.follows = "hjem-hm-modules/home-manager";
        import-tree.follows = "import-tree";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };
}
