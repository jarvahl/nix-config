{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/retro"
    cp "$src/SKILL.md" "$src/skill.yml" "$src/CHANGELOG.md" "$out/retro/"
    cp -r "$src/reference" "$out/retro/reference"
  '';

  pname = "pi-skill-retro";
  src = ./.;
  version = "1.1.0";
}
