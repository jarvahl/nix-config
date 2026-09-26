{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-tmux-alert";
  version = "0.1.0";
  src = ./pi-tmux-alert-src;

  installPhase = ''
    mkdir -p $out/bin
    cp index.ts $out/index.ts
    install -Dm755 bin/pi-tmux-alert $out/bin/pi-tmux-alert
  '';
}
