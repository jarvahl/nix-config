{ inputs, mkReadmeSection, ... }:
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

  git.ignore = [
    "breakglass.age"
    ".keys/"
  ];

  readme."nix-config" = mkReadmeSection 0 "";

  sops.file = {
    creation_rules = [
      {
        key_groups = [
          { age = [ "breakglass" ]; }
        ];
        path_regex = "pairing\\.sops\\.yaml$";
      }
    ];
    keys.breakglass = "age17dkg84wglz4nq2523fayp528qr82njr2znlwc6fvdhzy8k3pg3gsusgx2q";
  };

  systems = inputs.nixpkgs.lib.systems.flakeExposed;
}
