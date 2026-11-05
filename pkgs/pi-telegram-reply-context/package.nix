{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-telegram-reply-context"
    cp index.ts "$out/pi-telegram-reply-context/"
  '';

  pname = "pi-telegram-reply-context";
  src = ./.;
  version = "0.1.0";
}
