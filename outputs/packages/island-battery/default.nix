{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island/battery"
    cp *.qml "$out/share/island/battery/"
    cp ${./plugin.json} "$out/share/island/battery/plugin.json"
    runHook postInstall
  '';
  pname = "island-battery";
  src = ./src;
  version = "1.0.0";
}
