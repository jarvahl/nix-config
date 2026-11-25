{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/commit-planning"
    cp "$src/SKILL.md" "$out/commit-planning/SKILL.md"
  '';

  pname = "pi-skill-commit-planning";
  src = ./.;
  version = "0.1.0";
}
