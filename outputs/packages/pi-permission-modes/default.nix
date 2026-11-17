{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-permission-modes"
    cp index.ts utils.ts "$out/pi-permission-modes/"
  '';

  meta = {
    description = "Permission mode cycle extension for the Pi coding agent";
    homepage = "https://github.com/aprimediet/pi-permission-modes";
    license = lib.licenses.mit;
  };

  pname = "pi-permission-modes";
  src = fetchFromGitHub {
    hash = "sha256-sxWLuRSDCbZu+4ZD2mDNM0n6LUwhoQ9kTKKZBVhhhl0=";
    owner = "aprimediet";
    repo = "pi-permission-modes";
    rev = "0fe524f0ae94bb3ee009308abf9499442a98b6b7";
  };
  version = "1.2.2";
}
