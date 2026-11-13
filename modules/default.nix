{ config, inputs, ... }:
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

  sops.file = {
    default_key = "breakglass";
    keys.breakglass = "age17dkg84wglz4nq2523fayp528qr82njr2znlwc6fvdhzy8k3pg3gsusgx2q";
  };

  systems = inputs.nixpkgs.lib.systems.flakeExposed;

  perSystem =
    { pkgs, ... }:
    {
      packages = config.flakelight.outputs.packages.${pkgs.system};
    };
}
