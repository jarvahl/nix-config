{ stdenvNoCC
, rustPlatform
, fetchFromGitHub
, pkg-config
, wayland
, libxkbcommon
, libinput
, dbus
}:
let
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "agent-sh";
    repo = "computer-use-linux";
    rev = "b123144";
    hash = "sha256-8jCc+zymnEC9yWs19ijZT/I2eCMHq9Is6j7RDhtzhSw=";
  };

  binary = rustPlatform.buildRustPackage {
    pname = "computer-use-linux";
    inherit version src;
    cargoHash = "sha256-sxDoTb1EZKli9H/8pfB0odks9aDXKSn+LBCQDTRO8wc=";
    doCheck = false; # Nix build sandboxes have no session D-Bus/uinput.
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ dbus libinput libxkbcommon wayland ];
  };

  pi = stdenvNoCC.mkDerivation {
    pname = "computer-use-linux-pi";
    inherit version src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/pi/extension $out/skills/how-to-use-computer-use-linux $out/npm/bin
      cp -r pi/extension/. $out/pi/extension/
      cp -r skills/computer-use-linux/. $out/skills/how-to-use-computer-use-linux/
      sed -i '0,/^name: computer-use-linux$/s//name: how-to-use-computer-use-linux/' \
        $out/skills/how-to-use-computer-use-linux/SKILL.md
      ln -s ${binary}/bin/computer-use-linux \
        $out/npm/bin/computer-use-linux-linux-x64
    '';
  };
in
binary.overrideAttrs (_old: {
  passthru.pi = pi;
})
