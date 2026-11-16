{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-firefox-bridge";
  version = "1.0.0";
  src = ./src;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/pi-firefox-bridge
    cp *.ts $out/pi-firefox-bridge/
  '';
}
