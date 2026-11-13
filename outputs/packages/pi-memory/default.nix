{
  buildNpmPackage,
  fetchurl,
  lib,
}:

buildNpmPackage {
  pname = "pi-memory";
  version = "0.15.1";

  src = fetchurl {
    hash = "sha256-l2aItlHXaJezRac/+ejJx674097UwV7kHLS5vHrMjWo=";
    url = "https://registry.npmjs.org/@shog-lab/pi-memory/-/pi-memory-0.15.1.tgz";
  };

  sourceRoot = "package";
  npmDepsHash = "sha256-JAiz2h35bzn0M5eCHWj7xrQjRbsVjjEywBbzBiwfKPs=";
  dontNpmBuild = true;
  npmFlags = [ "--legacy-peer-deps" ];
  patches = [ ./better-sqlite3.patch ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/pi-memory"
    cp -r dist skills package.json bin "$out/pi-memory/"
    cp -r node_modules "$out/pi-memory/"
    runHook postInstall
  '';

  meta = {
    description = "Persistent, inspectable memory with hybrid retrieval and knowledge-graph triples for Pi";
    homepage = "https://github.com/shog-lab/pi-mind";
    license = lib.licenses.mit;
  };
}
