{ mkPiExtension, fetchFromGitHub }:

mkPiExtension {
  pname = "pi-prompt-timer";
  sourcePath = "extensions/prompt-timer/index.ts";
  version = "0.3.0";

  src = fetchFromGitHub {
    hash = "sha256-LeyrTaCFpWrPhN6Couzh2VbLkA61ZrxPue9Y7mUBx8U=";
    owner = "nomeelnoj";
    repo = "pi-prompt-timer";
    rev = "ea5f40e00fc903fbfad5a73987c5f80d4ab61dc9";
  };
}
