{ inputs, ... }:
{
  flake-file.inputs = {
    flake-file.url = "github:denful/flake-file";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  imports = with inputs.flake-file.flakeModules; [
    auto-follow
    default
    import-tree
  ];

  systems = inputs.nixpkgs.lib.systems.flakeExposed;
}
