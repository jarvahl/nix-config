{ buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  dontNpmBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-web-access"
    cp -- *.ts package.json "$out/pi-web-access/"
    cp -r node_modules "$out/pi-web-access/"
  '';

  npmDepsHash = "sha256-W8NDa2tq+qGxF4z4lTQXF6mNAOC3bWiuyeeNIIEbStc=";

  pname = "pi-web-access";
  src = fetchFromGitHub {
    hash = "sha256-QfwEKSqOTc/VhPonFySNsgDAOkx9ROf+PnEF9v/iCow=";
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "322e44fafc1aaa691779cdf2116584e67edd7645";
  };
  version = "0.47.0";
}
