{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-memory"
    cp index.ts "$out/pi-memory/"
  '';

  pname = "pi-memory";

  src = fetchFromGitHub {
    hash = "sha256-JHhR4Wwhq5VVEVSbjBBkui7T2dkcLvCzvX7PvWkN/2I=";
    owner = "jayzeng";
    repo = "pi-memory";
    rev = "1e276a762a666a7031459fdf7af018cc7966663e";
  };
  version = "0.4.2";
}
