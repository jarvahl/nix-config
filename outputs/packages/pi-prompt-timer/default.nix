{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-prompt-timer"
    cp -r extensions/prompt-timer/index.ts "$out/pi-prompt-timer/"
  '';

  pname = "pi-prompt-timer";

  src = fetchFromGitHub {
    hash = "sha256-LeyrTaCFpWrPhN6Couzh2VbLkA61ZrxPue9Y7mUBx8U=";
    owner = "nomeelnoj";
    repo = "pi-prompt-timer";
    rev = "ea5f40e00fc903fbfad5a73987c5f80d4ab61dc9";
  };
  version = "0.3.0";
}
