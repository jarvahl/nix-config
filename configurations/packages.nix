{ inputs, lib, ... }:
let
  packagesDir = toString ../packages;
  packageFiles = ((inputs.import-tree.match ".*/package\\.nix").addPath ../packages).files;

  packageTree = lib.foldl' lib.recursiveUpdate { } (map
    (packageFile:
      lib.setAttrByPath
        (lib.splitString "/" (builtins.dirOf (lib.removePrefix "${packagesDir}/" (toString packageFile))))
        { __package = packageFile; })
    packageFiles);

  overlay = final: prev:
    let
      importNode = previous: node:
        if node ? __package then
          final.callPackage node.__package { }
        else
          (if builtins.isAttrs previous then previous else { })
          // lib.mapAttrs
            (name: importNode (if builtins.isAttrs previous then previous.${name} or { } else { }))
            node;
    in
    lib.mapAttrs (name: importNode (prev.${name} or { })) packageTree;
in
{
  flake.overlays.default = overlay;

  den.default.nixos.nixpkgs.overlays = [ overlay ];

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
