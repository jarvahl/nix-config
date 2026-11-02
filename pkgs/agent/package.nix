{
  buildNpmPackage,
  makeWrapper,
  nodejs,
}:

buildNpmPackage {
  pname = "agent";
  version = "0.1.0";

  src = ./.;

  dontNpmInstall = true;
  nativeBuildInputs = [ makeWrapper ];
  npmDepsHash = "sha256-cGnWx8CCvAVvayCZ9UvZ/YH8CPT1ETHefB0enJcbf+k=";

  installPhase = ''
    mkdir -p "$out/lib/agent" "$out/bin"
    cp -r dist "$out/lib/agent/"
    makeWrapper ${nodejs}/bin/node "$out/bin/agent" --add-flags "$out/lib/agent/dist/cli.js"
  '';
}
