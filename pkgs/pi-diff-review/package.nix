{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "pi-diff-review";
  version = "0.1.27";

  src = fetchFromGitHub {
    hash = "sha256-4ecBoHZtBZDP+NnoMzxkKRXKoJm1Zl+/nDR8G1Rous4=";
    owner = "cmpadden";
    repo = "pi-diff-review";
    rev = "d15ab76d41d35a7ead26441826714cd297ede224";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/pi-diff-review" "$out/src"
    cp extensions/review.ts "$out/pi-diff-review/index.ts"
    cp -r src/* "$out/src/"
    # Avoid a runtime dependency on the optional parser package.
    awk '
      /^import { parsePatchFiles/ { next }
      /^import type {$/ { pierre_import = 1; next }
      pierre_import && /^} from "@pierre\/diffs";$/ { pierre_import = 0; next }
      pierre_import { next }
      /^function parseDiffWithPierre/ { pierre_function = 1; next }
      /^function parseDiffManual/ { pierre_function = 0 }
      pierre_function { next }
      { gsub(/const reviewLines = parseDiffWithPierre\(diffText\);/, "const reviewLines = []; "); print }
    ' "$out/src/diff/parser.ts" > "$out/src/diff/parser.ts.tmp"
    mv "$out/src/diff/parser.ts.tmp" "$out/src/diff/parser.ts"
  '';
}
