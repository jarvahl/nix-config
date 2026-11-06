{
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p "$out/pi-telegram"
    cp index.ts package.json "$out/pi-telegram/"
    cp -r node_modules "$out/pi-telegram/"
  '';
  npmDepsHash = "sha256-QUvD5j7nWeFtBqQ9RxiWfT01H08nAydoPUhm89yZVPU=";
  patches = [ ./empty-message.patch ];
  pname = "pi-telegram";
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';
  src = fetchFromGitHub {
    hash = "sha256-2Gvr3AogpEHkmGkHetVfaPW9VHyMH9TZaK3swKbvQCw=";
    owner = "badlogic";
    repo = "pi-telegram";
    rev = "cb34008460b6c1ca036d92322f69d87f626be0fc";
  };
  version = "0.1.0";
}
