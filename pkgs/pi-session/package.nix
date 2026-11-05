{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-session"
    cp -r packages/pi-session/src/. "$out/pi-session/"
  '';

  pname = "pi-session";
  src = fetchFromGitHub {
    hash = "sha256-KW07lcEm77cFpcxjKriIIhUeSiWaTdWXBbztzkEhL6k=";
    owner = "Yesifan";
    repo = "pi-packages";
    rev = "6eb9275d1930a51a48512b95598a7cfcfac46b89";
  };
  version = "0.1.1";
}
