{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-telegram"
    cp index.ts "$out/pi-telegram/index.ts"
  '';

  patches = [
    ./draft-finalization.patch
    ./headless-autostart.patch
    ./ignore-empty-updates.patch
  ];

  pname = "pi-telegram";
  src = fetchFromGitHub {
    hash = "sha256-2Gvr3AogpEHkmGkHetVfaPW9VHyMH9TZaK3swKbvQCw=";
    owner = "badlogic";
    repo = "pi-telegram";
    rev = "cb34008460b6c1ca036d92322f69d87f626be0fc";
  };
  version = "0.1.0";
}
