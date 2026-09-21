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
  version = "0.7.1";
  src = fetchFromGitHub {
    owner = "agent-sh";
    repo = "computer-use-linux";
    rev = "d6fda11a7b1a52114e1221c56b93ff2c44173cee";
    hash = "sha256-L+5/2NQ7urS/TvlOEZn+A3b88gGV4tLUDDQMEZ7kLCQ=";
  };

  binary = rustPlatform.buildRustPackage {
    pname = "computer-use-linux";
    inherit version src;
    cargoHash = "sha256-ckkjnf0oIfpWjuUA7zVT6ardq5n3UdHOqgFVG93pAFA=";
    doCheck = false;
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ dbus libinput libxkbcommon wayland ];
  };

  pi = stdenvNoCC.mkDerivation {
    pname = "computer-use-linux-pi";
    inherit version src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/pi/extension $out/skills/computer-use-linux $out/npm/bin
      cp -r pi/extension/. $out/pi/extension/
      cp -r skills/computer-use-linux/. $out/skills/computer-use-linux/
      ln -s ${binary}/bin/computer-use-linux \
        $out/npm/bin/computer-use-linux-linux-x64
    '';
  };
in
binary.overrideAttrs (_old: {
  passthru.pi = pi;
})
