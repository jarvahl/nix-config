{ mkPiExtension, fetchFromGitHub }:

mkPiExtension {
  pname = "pi-core-skill-tool";
  sourcePath = "packages/core/pi-core-skill-tool/src/index.ts";
  version = "1.0.12";

  src = fetchFromGitHub {
    hash = "sha256-SCvTHU3aoSVuEovb6F5La7F/YPt63m8Bg1I/Y0fM2eM=";
    owner = "arhen";
    repo = "pi-extensions";
    rev = "267bbdb";
  };
}
