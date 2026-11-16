{
  fetchFromGitHub,
  fetchurl,
  lib,
  openssl,
  pkg-config,
  rustPlatform,
  stdenvNoCC,
}:

let
  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "firefox-agent-bridge";
    rev = "b8b0c146bae4e547b227cca3862df511b43ceabe";
    hash = "sha256-rQx+qpZJb4EC7T4CoCDOywFX/GCvMawCnhEWzQFCqu0=";
  };

  extension = fetchurl {
    name = "browser-agent-bridge-0.9.7.xpi";
    url = "https://github.com/1jehuang/firefox-agent-bridge/releases/download/v0.10.1/browser-agent-bridge-0.9.7.xpi";
    sha256 = "4001f85de3c5501371ebcb7c8d5257398978e92438bbefa5c9e1761a50180915";
  };

  native = rustPlatform.buildRustPackage {
    pname = "firefox-agent-bridge-native";
    version = "1.0.0";
    src = "${src}/rust-cli";
    cargoLock = {
      lockFile = "${src}/rust-cli/Cargo.lock";
      outputHashes."bronzewarden-0.1.0" = "sha256-PfHE8dikxP/CnJa8lDROR4cbGEzRuEXAa/gRsKx7GSs=";
    };
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ openssl ];
  };
in
stdenvNoCC.mkDerivation {
  pname = "firefox-agent-bridge";
  version = "0.10.1";

  unpackPhase = ''
    cp -r ${src} source
    chmod -R u+w source
  '';

  installPhase = ''
    mkdir -p $out/bin $out/libexec $out/share/firefox-agent-bridge/native-messaging-hosts $out/share/mozilla/native-messaging-hosts $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
    cp ${extension} $out/share/firefox-agent-bridge/firefox-agent-bridge.xpi
    install -m 0755 ${native}/bin/firefox-agent-bridge-host $out/libexec/firefox-agent-bridge-host
    install -m 0755 ${native}/bin/browser $out/bin/browser

    substitute source/native-host/manifest.json $out/share/firefox-agent-bridge/native-messaging-hosts/firefox_agent_bridge.json \
      --replace-fail __HOST_PATH__ $out/libexec/firefox-agent-bridge-host \
      --replace-fail firefox-agent-bridge@local browser-agent-bridge@1jehuang.github.io
    cp $out/share/firefox-agent-bridge/native-messaging-hosts/firefox_agent_bridge.json $out/share/mozilla/native-messaging-hosts/

    cp $out/share/firefox-agent-bridge/firefox-agent-bridge.xpi $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/browser-agent-bridge@1jehuang.github.io.xpi
  '';

  passthru.addonId = "browser-agent-bridge@1jehuang.github.io";

  meta = {
    description = "Declarative Firefox Agent Bridge for Pi";
    homepage = "https://github.com/1jehuang/firefox-agent-bridge";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
