{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island/brightness"
    cp *.qml "$out/share/island/brightness/"
    cp ${./plugin.json} "$out/share/island/brightness/plugin.json"
    runHook postInstall
  '';
  pname = "island-brightness";
  src = ./src;
  version = "1.0.0";
}
