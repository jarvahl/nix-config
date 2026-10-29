{ mkPiExtension, fetchFromGitHub }:

mkPiExtension {
  pname = "pi-self-compact";
  sourcePath = "extensions/index.ts";
  version = "0.2.0";

  src = fetchFromGitHub {
    hash = "sha256-csv/g4XGsL7v9rk9ybhU/g2ec2xHlgglwhj3tyzvmdk=";
    owner = "saiday";
    repo = "pi-self-compact";
    rev = "de04f436207cf4fc45458739366cd7f7f61f11e7";
  };
}
