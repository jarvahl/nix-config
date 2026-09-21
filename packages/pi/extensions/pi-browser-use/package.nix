{ buildNpmPackage
, fetchurl
}:

buildNpmPackage {
  pname = "pi-browser-use";
  version = "0.1.16";

  src = fetchurl {
    url = "https://registry.npmjs.org/@amaster.ai/pi-browser-use/-/pi-browser-use-0.1.16.tgz";
    hash = "sha256-u+rmdM40TO2pwdPUveOjsaMO68u9B2RbGJN3arxy19E=";
  };

  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-r5kI5+P6c5shQfH75bR7GG1vziF87Yk1fieKDT5caqs=";
  dontNpmBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r dist package.json node_modules $out/
  '';
}
