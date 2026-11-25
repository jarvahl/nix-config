{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/skill-creator"
    cp "$src/SKILL.md" "$src/LICENSE.txt" "$out/skill-creator/"
  '';

  pname = "pi-skill-creator";
  src = ./.;
  version = "0.2.0";
}
