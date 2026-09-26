{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-token-killer";
  version = "0.1.0";
  src = ./pi-token-killer-src;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/builtins $out/skills/pi-token-killer
    substitute index.ts $out/index.ts \
      --replace-fail '@BUILTIN_DIR@' "$out/builtins"
    install -Dm755 builtins/git $out/builtins/git
    install -Dm755 builtins/nixos-rebuild $out/builtins/nixos-rebuild
    install -Dm755 builtins/nix $out/builtins/nix
    install -Dm644 skills/pi-token-killer/SKILL.md $out/skills/pi-token-killer/SKILL.md

    runHook postInstall
  '';
}
