{ buildNpmPackage, fetchFromGitHub, jq }:

buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.32.1";
  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "8243eba3421e301c88c047444f34ab7d5d57163e";
    hash = "sha256-Z+Nc7aQJFnZKYAe6yQN0CFwYuekNahAcFRg+dDBpRVU=";
  };
  npmDepsHash = "sha256-MtDyee9eaqjc8m6f1Qqt+SEVBBme5doB9lBCb5FXzDk=";
  npmInstallFlags = [ "--omit=dev" ];
  postPatch = ''
    lockfile=$(mktemp)
    ${jq}/bin/jq \
      'del(.packages[] | select(.dev == true)) | del(.packages[""].devDependencies)' \
      package-lock.json > "$lockfile"
    mv "$lockfile" package-lock.json
    ${jq}/bin/jq 'del(.devDependencies)' package.json > "$lockfile"
    mv "$lockfile" package.json
  '';
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
