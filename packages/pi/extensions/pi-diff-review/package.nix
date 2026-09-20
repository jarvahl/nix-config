{ buildNpmPackage
, fetchFromGitHub
, jq

}:

buildNpmPackage {
  pname = "pi-diff-review";
  version = "0.1.27";

  src = fetchFromGitHub {
    owner = "cmpadden";
    repo = "pi-diff-review";
    rev = "d15ab76d41d35a7ead26441826714cd297ede224";
    hash = "sha256-4ecBoHZtBZDP+NnoMzxkKRXKoJm1Zl+/nDR8G1Rous4=";
  };

  nativeBuildInputs = [ jq ];

  # Nix only needs the runtime dependency; dev/peer packages in upstream's
  # manifest make the npm dependency fetcher pull in unrelated libraries.
  postPatch = ''
    jq 'del(.devDependencies, .peerDependencies, .peerDependenciesMeta, .scripts)' \
      package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-sdOsaT7pkGZ0sUY26Qfze4GpOtd2YQu8HzIp78IfOag=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r extensions src package.json node_modules $out/
    runHook postInstall
  '';
}
