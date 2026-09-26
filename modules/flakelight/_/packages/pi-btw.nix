{ buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage {
  pname = "pi-btw";
  version = "0.60.0";
  src = fetchFromGitHub {
    owner = "narumiruna";
    repo = "pi-extensions";
    rev = "07360601b590218f2934290cd57bc7ad8ac0e1bf";
    hash = "sha256-DJErSwALyGMYgmsTF5WPevqgkpiQBcd3pAInZdIZeAE=";
  };
  npmDepsHash = "sha256-MfRaUEBly1A7/xymoXn0ExF9JihbIwNrXtR7VidKmk0=";
  npmDepsFetcherVersion = 2;
  npmInstallFlags = [ "--legacy-peer-deps" ];
  npmBuildScript = "build";
  npmBuildFlags = [
    "--workspace=@narumitw/pi-tui-kit"
    "--workspace=@narumitw/pi-btw"
  ];

  installPhase = ''
    rm -rf node_modules/@narumitw
    mkdir -p node_modules/@narumitw/pi-tui-kit
    cp -r packages/pi-tui-kit/dist packages/pi-tui-kit/package.json node_modules/@narumitw/pi-tui-kit/
    mkdir -p $out
    cp -r packages/pi-btw/dist packages/pi-btw/package.json $out/
    cp -r node_modules $out/
  '';
}
