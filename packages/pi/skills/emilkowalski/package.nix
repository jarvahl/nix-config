{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "pi-skills-emilkowalski";
  version = "85e8e2363b713506e1d5b6e07a0eb2da66be1bc3";

  src = fetchFromGitHub {
    owner = "emilkowalski";
    repo = "skills";
    rev = "85e8e2363b713506e1d5b6e07a0eb2da66be1bc3";
    hash = "sha256-/t+rEm8Qk+mQW4jpUpI78s+WXlb8e77lZipRtHtX398=";
  };

  dontBuild = true;

  installPhase = ''
    cp -r skills $out
  '';
}
