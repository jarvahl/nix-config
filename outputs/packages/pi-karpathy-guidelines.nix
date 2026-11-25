{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out"
    find . -path './.git' -prune -o -type f -name '*.md' -exec cp --parents {} "$out" \;
    cp CLAUDE.md "$out/AGENTS.md"
  '';

  pname = "pi-karpathy-guidelines";
  src = fetchFromGitHub {
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
  };
  version = "unstable-2026-06-07";
}
