{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-core-skill-tool"
    cp -r packages/core/pi-core-skill-tool/src/index.ts "$out/pi-core-skill-tool/"
  '';

  pname = "pi-core-skill-tool";

  src = fetchFromGitHub {
    hash = "sha256-SCvTHU3aoSVuEovb6F5La7F/YPt63m8Bg1I/Y0fM2eM=";
    owner = "arhen";
    repo = "pi-extensions";
    rev = "267bbdb";
  };
  version = "1.0.12";
}
