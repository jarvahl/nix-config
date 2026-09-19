{ buildNpmPackage
, fetchFromGitHub
, jq
,
}:

buildNpmPackage {
  pname = "pi-subagent";
  version = "0.22.2";
  src = fetchFromGitHub {
    owner = "bacnh85";
    repo = "pi-extensions";
    rev = "fdf44f60a4ad34359a855de70f0de2edb64c7f2b";
    hash = "sha256-hvx5jfg5Y2KTasOx5LcxisXO38rte9jvXL7UADTtN88=";
  };
  sourceRoot = "source/pi-subagent";
  npmDepsHash = "sha256-iYJwBVf8V4zPUL36nZvUIyqKZ5x7X2GBcZzMGEAXhhs=";
  npmInstallFlags = [ "--omit=dev" "--omit=peer" ];
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
