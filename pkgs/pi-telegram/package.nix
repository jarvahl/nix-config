{ buildNpmPackage }:

buildNpmPackage {
  dontNpmBuild = true;
  doCheck = true;
  checkPhase = "npm test";
  installPhase = ''
    mkdir -p "$out/pi-telegram"
    cp index.ts package.json "$out/pi-telegram/"
    cp -r node_modules "$out/pi-telegram/"
  '';
  npmDepsHash = "sha256-EFJnvmL/+ydLXS6aULmXN/TX4S7eO4wmsmDy672iJhk=";
  pname = "pi-telegram";
  src = ./.;
  version = "0.2.0";
}
