{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/import-tree"
    cp "$src/SKILL.md" "$out/import-tree/SKILL.md"
  '';

  pname = "pi-skill-import-tree";
  src = ./.;
  version = "0.1.0";
}
