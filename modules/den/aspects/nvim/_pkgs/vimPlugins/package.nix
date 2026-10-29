{ pkgs }:

pkgs.vimPlugins
// pkgs.lib.packagesFromDirectoryRecursive {
  callPackage = pkgs.lib.callPackageWith pkgs;
  directory = ./plugins;
}
