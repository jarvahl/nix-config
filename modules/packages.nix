{ ... }:

let
  loadPackages =
    pkgs:
    pkgs.lib.packagesFromDirectoryRecursive {
      callPackage = pkgs.lib.callPackageWith (pkgs // { inherit pkgs; });
      directory = ../packages;
    };

in
{
  den.default.nixos.nixpkgs.overlays = [
    (_final: prev: loadPackages prev)
  ];
}
