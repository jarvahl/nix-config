{ inputs, ... }:
let
  packageFiles = ((inputs.import-tree.match ".*/package\\.nix").addPath ../pkgs).files;

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

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
