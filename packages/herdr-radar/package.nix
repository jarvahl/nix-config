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

  postPatch = ''
    substituteInPlace lib/paths.js \
      --replace-fail "  identity.env('STATE') ?? process.env.HERDR_PLUGIN_STATE_DIR ?? path.join(herdrStateDir(), 'plugins', pluginId());" "  path.join(herdrStateDir(), 'plugin-state', pluginId());"
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
    chmod +x $out/bin/*.js $out/bin/*.sh 2>/dev/null || true
  '';
}
