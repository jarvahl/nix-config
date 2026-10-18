{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-ponytail";
  version = "5.3.2";

  src = fetchFromGitHub {
    hash = "sha256-sVnxA4rfxa2SlS2g+2+q3odRq0VJz1z7PEVHW2QRPQI=";
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "09c434ab73ca43761c5d8b0c5d341926c2fba710";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-ponytail/skills"
    cp pi-extension/index.js "$out/pi-ponytail/index.js"
    cp -r skills/* "$out/pi-ponytail/skills/"
  '';
}
