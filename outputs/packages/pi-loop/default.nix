{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-loop"
    cp -r src/. "$out/pi-loop"
  '';

  pname = "pi-loop";
  src = fetchFromGitHub {
    hash = "sha256-K6bvk4A/Kq6QQk+kZjHUh8li52Rg0XpMLeWXzGgkbvo=";
    owner = "ArtemisAI";
    repo = "pi-loop";
    rev = "9c72768c69934d811aaa8dea998a3c72e4ab5cb4";
  };
  version = "0.3.1";
}
