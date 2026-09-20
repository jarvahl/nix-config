{ fetchFromGitHub
, stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "herdr-radar";
  version = "1.3.5";
  src = fetchFromGitHub {
    owner = "hhdebb";
    repo = "herdr-radar";
    rev = "45eacc4c9746ee13f6cf56e61099239ce4a02cf0";
    hash = "sha256-QhIdKRvehGZBU9mS4eVKJIkRxEQqvkwaAf1qg78IvLI=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
    chmod +x $out/bin/*.js $out/bin/*.sh 2>/dev/null || true
  '';
}
