{ inputs, lib, ... }:
let
  packageFiles = ((inputs.import-tree.match ".*/package\\.nix").addPath ../pkgs).files;

  packagePath = packageFile:
    let
      match = builtins.match ".*/pkgs/(.*)/package\\.nix" (toString packageFile);
    in
    if match == null then
      throw "package path is outside pkgs: ${toString packageFile}"
    else
      lib.splitString "/" (builtins.elemAt match 0);

  overlay = final: _:
    lib.foldl'
      (
        packages: packageFile:
          lib.recursiveUpdate packages (
            lib.setAttrByPath (packagePath packageFile) (final.callPackage packageFile { })
          )
      )
      { }
      packageFiles;
in
{
  den.default.nixos.nixpkgs.overlays = [ overlay ];

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
