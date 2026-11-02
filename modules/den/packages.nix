{ ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages = pkgs.lib.packagesFromDirectoryRecursive {
        callPackage = pkgs.callPackage;
        directory = ../../pkgs;
      };
    };
}
