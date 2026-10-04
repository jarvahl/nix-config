{ inputs, lib, ... }:

{
  flake-file.inputs = {
    flake-file.url = lib.mkForce "github:denful/flake-file";

    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
  ];
}
