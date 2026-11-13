{
  buildNpmPackage,
  fetchurl,
  lib,
}:

buildNpmPackage {
  pname = "pi-browser-use";
  version = "0.12.15";

  src = fetchurl {
    hash = "sha256-DRlKP8ys5FeEvB80+BdgRCvrYemfpxQVtbDu4NAVSHo=";
    url = "https://registry.npmjs.org/pi-browser-use/-/pi-browser-use-0.12.15.tgz";
  };

  sourceRoot = "package";
  npmDepsHash = "sha256-1Ol0tvGodPtPWS5WKjnsSYpfbcB4YeZusPpywmXO9OY=";
  dontNpmBuild = true;
  npmFlags = [ "--legacy-peer-deps" ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/pi-browser-use"
    cp -r dist skills package.json plugin.json mcp.json "$out/pi-browser-use/"
    cp -r node_modules "$out/pi-browser-use/"
    runHook postInstall
  '';

  meta = {
    description = "Opinionated browser automation extension for Pi";
    homepage = "https://github.com/0xPlayerOne/pi-browser-use";
    license = lib.licenses.mit;
  };
}
