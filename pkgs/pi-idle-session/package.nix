{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-idle-session";
  version = "0.1.0";
  src = ./.;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/pi-idle-session
    cp index.ts $out/pi-idle-session/index.ts
  '';
}
