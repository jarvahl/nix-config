# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    agent-files = {
      url = "github:jarvahl/agent-files";
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
    den = {
      url = "github:denful/den";
    };
    files = {
      url = "github:mightyiam/files";
      flake = false;
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
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdnix = {
      url = "github:Ra77a3l3-jar/herdnix";
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
    import-tree = {
      url = "github:denful/import-tree";
    };
    just-file = {
      url = "github:jarvahl/just-file";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:jarvahl/pi.nix";
      inputs.flake-file.follows = "flake-file";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks-nix.follows = "git-hooks-nix";
      inputs.import-tree.follows = "import-tree";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
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
