{ buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage {
  pname = "pi-mcp-extension";
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "irahardianto";
    repo = "pi-mcp-extension";
    rev = "8a01fc53f3289d2e8eb492d67ba45cd84d64e7f2";
    hash = "sha256-anSDweXAyb+f/O3RxAz4/YhMNOGDdzEBVRTn/rHqees=";
  };
  npmDepsHash = "sha256-S0LZg0iwmW0MiFEpq/RIwZcQ95uUk1iLKFAKIbmOI3A=";
  dontNpmBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r src package.json $out/
    cp -r node_modules $out/
  '';
}
