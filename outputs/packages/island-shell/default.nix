{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/island"
    cp *.qml "$out/share/island/"
    runHook postInstall
  '';
  pname = "island-shell";
  src = ./src;
  version = "1.0.0";
}
