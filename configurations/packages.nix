{ inputs, ... }:
let
  packageFiles = ((inputs.import-tree.match ".*/package\\.nix").addPath ../packages).files;

  overlay = final: _:
    builtins.listToAttrs (map
      (packageFile: {
        name = builtins.baseNameOf (builtins.dirOf packageFile);
        value = final.callPackage packageFile { };
      })
      packageFiles);
in
{
  flake.overlays.default = overlay;

  den.default.nixos.nixpkgs.overlays = [ overlay ];

  perSystem = { system, pkgs, ... }: {
    packages.colibri = pkgs.colibri;

    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
