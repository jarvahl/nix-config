{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "pi-skills-anthropics";
  version = "34040c9c568585f6929bedeaad110ad08f079624";

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "34040c9c568585f6929bedeaad110ad08f079624";
    hash = "sha256-tI4bTTBfI1ylltklGyiyA7pLoKXEWtrT6lrmwrpLbCw=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r skills $out/skills
  '';
}
