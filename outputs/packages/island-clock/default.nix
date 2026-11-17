{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island/clock"
    cp *.qml "$out/share/island/clock/"
    cp ${./plugin.json} "$out/share/island/clock/plugin.json"
    runHook postInstall
  '';
  pname = "island-clock";
  src = ./src;
  version = "1.0.0";
}
