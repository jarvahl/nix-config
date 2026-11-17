{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island/launcher"
    cp *.qml "$out/share/island/launcher/"
    cp ${./plugin.json} "$out/share/island/launcher/plugin.json"
    runHook postInstall
  '';
  pname = "island-launcher";
  src = ./src;
  version = "1.0.0";
}
