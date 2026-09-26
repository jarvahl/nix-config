{ fetchzip, lib }:

fetchzip rec {
  name = "pi-mnemosyne-${version}";
  version = "0.1.0";

  url = "https://registry.npmjs.org/@mnemosyne-oss/pi-mnemosyne/-/pi-mnemosyne-${version}.tgz";
  hash = "sha256-0PN5owb+IGdMyX4NiniCekIXGx5MheqrKrVO+2GGV+s=";

  meta = {
    description = "Mnemosyne memory extension and skill for Pi";
    homepage = "https://github.com/mnemosyne-oss/pi-mnemosyne";
    license = lib.licenses.mit;
  };
}
