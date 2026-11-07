{ stdenvNoCC, nodejs }:

stdenvNoCC.mkDerivation {
  pname = "pi-matrix-synapse";
  version = "0.1.0";
  src = ./.;
  nativeCheckInputs = [ nodejs ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    npm test
    runHook postCheck
  '';
  installPhase = ''
    mkdir -p "$out/pi-matrix-synapse"
    cp index.ts package.json "$out/pi-matrix-synapse/"
  '';
}
