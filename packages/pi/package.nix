{ pkgs }:

let
  mkPiExtension =
    {
      pname,
      sourcePath,
      src,
      version,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname src version;

      dontBuild = true;

      installPhase = ''
        mkdir -p "$out/${pname}"
        cp -r ${sourcePath} "$out/${pname}/"
      '';
    };

  localScope = pkgs // {
    inherit mkPiExtension;
  };
in
pkgs.lib.packagesFromDirectoryRecursive {
  callPackage = pkgs.lib.callPackageWith localScope;
  directory = ./extensions;
}
