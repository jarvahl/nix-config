{
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  dontNpmBuild = true;
  npmDepsHash = "sha256-QUvD5j7nWeFtBqQ9RxiWfT01H08nAydoPUhm89yZVPU=";

  installPhase = ''
    mkdir -p "$out/pi-telegram"
    cp index.ts package.json "$out/pi-telegram/"
    cp -r node_modules "$out/pi-telegram/"
  '';

  patches = [
    ./draft-finalization.patch
    ./headless-autostart.patch
    ./ignore-empty-updates.patch
    ./reply-context.patch
    ./formatting.patch
    ./chat-id-context.patch
    ./outgoing-message-context.patch
    ./progress-preview.patch
  ];

  pname = "pi-telegram";
  src = fetchFromGitHub {
    hash = "sha256-2Gvr3AogpEHkmGkHetVfaPW9VHyMH9TZaK3swKbvQCw=";
    owner = "badlogic";
    repo = "pi-telegram";
    rev = "cb34008460b6c1ca036d92322f69d87f626be0fc";
  };
  version = "0.1.0";

  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';
}
