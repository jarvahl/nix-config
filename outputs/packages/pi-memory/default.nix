{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "pi-memory";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "jayzeng";
    repo = "pi-memory";
    rev = "768b8b9798e364ef0ee09b80cc9203a63afa8e92";
    hash = "sha256-20hbBZ3loTvpun+CTUp2dRU77eKtSw4J2bS8rvsRGgM=";
  };

  installPhase = ''
    mkdir -p "$out/pi-memory"
    cp index.ts "$out/pi-memory/"
  '';

  meta = {
    description = "Persistent Markdown memory extension for Pi with optional qmd search";
    homepage = "https://github.com/jayzeng/pi-memory";
    license = lib.licenses.mit;
  };
}
