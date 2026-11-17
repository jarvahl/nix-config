{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island/volume"
    cp *.qml "$out/share/island/volume/"
    cp ${./plugin.json} "$out/share/island/volume/plugin.json"
    runHook postInstall
  '';
  pname = "island-volume";
  src = ./src;
  version = "1.0.0";
}
