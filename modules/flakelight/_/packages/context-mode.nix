{ buildNpmPackage
, fetchFromGitHub
, lib
}:

buildNpmPackage rec {
  pname = "context-mode";
  version = "1.0.169";

  src = fetchFromGitHub {
    owner = "mksglu";
    repo = "context-mode";
    rev = "v${version}";
    hash = "sha256-1pV56ZB2aqod+C0kb5myuiWLAJ7+opiaurwZZ3BGKYk=";
  };

  postPatch = ''
    cp ${./context-mode-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-BVKvJlwHdWUqTqdJF16SGe8hMrnUgs+dPCAmtAKvHKU=";
  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = {
    description = "Context window optimization extension for Pi";
    homepage = "https://github.com/mksglu/context-mode";
    license = lib.licenses.elastic20;
  };
}
