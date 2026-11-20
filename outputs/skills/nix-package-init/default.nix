{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/nix-package-init"
    cp "$src/SKILL.md" "$out/nix-package-init/SKILL.md"
  '';

  pname = "pi-skill-nix-package-init";
  src = ./.;
  version = "0.1.0";
}
