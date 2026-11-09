{
  buildNpmPackage,
  fetchurl,
  lib,
}:

buildNpmPackage {
  pname = "pi-subagents";
  version = "0.23.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@tintinweb/pi-subagents/-/pi-subagents-0.23.1.tgz";
    hash = "sha256-2Wg1t/xMS+/tPM4K7BbhgcKxcYCElO7khwVBEGalBlo=";
  };

  sourceRoot = "package";
  npmDepsHash = "sha256-hiToHKBcjzQYJsSGyiNsd4kS/hyNhAlhPDiQEHQqI3Y=";
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/pi-subagents"
    cp -r dist package.json node_modules "$out/pi-subagents/"
    runHook postInstall
  '';

  meta = {
    description = "Claude Code-style sub-agents and workflow orchestration for Pi";
    homepage = "https://github.com/tintinweb/pi-subagents";
    license = lib.licenses.mit;
  };
}
