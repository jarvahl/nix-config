{ stdenvNoCC, fetchFromGitHub, fetchurl }:

stdenvNoCC.mkDerivation {
  pname = "hyprcage";
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "hexadecimil";
    repo = "hyprcage";
    rev = "v0.3.0";
    hash = "sha256-yE8kmY8NuiIzSTPYBuOTNydqmOK0rs68hwb2kINROQU=";
  };
  binary = fetchurl {
    url = "https://github.com/hexadecimil/hyprcage/releases/download/v0.3.0/hyprcage-linux-amd64";
    hash = "sha256-wF/WN3joL5ik8VxG0mCj8cF0ni5mAXjeGcF/7yR8E1U=";
  };
  dontBuild = true;
  installPhase = ''
    install -Dm755 "$binary" "$out/bin/hyprcage"
    sed -i '3s/^description: /description: "/; 3s/$/"/' skills/hyprcage/SKILL.md
    mkdir -p "$out/share/hyprcage"
    cp -r skills "$out/share/hyprcage/"
  '';
  meta.mainProgram = "hyprcage";
}
