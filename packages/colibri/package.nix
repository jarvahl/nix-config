{ lib
, stdenv
, fetchFromGitHub
, python3
}:

stdenv.mkDerivation {
  pname = "colibri";
  version = "unstable-2026-09-14";

  src = fetchFromGitHub {
    owner = "JustVugg";
    repo = "colibri";
    rev = "f028d26b422144ed4a69ad9aeaee2553ce0f9572";
    hash = "sha256-l4LdWvk3z7L7+XplKtKJD78KcVcUHeUd9f9H/T58YY0=";
  };

  dontConfigure = true;

  postPatch = ''
    # INFO: patched shebangs keep the launcher and runtime tools usable from nix run.
    patchShebangs c
  '';

  buildPhase = ''
    # INFO: build only GLM and OLMoE CPU engines; upstream install builds every model backend.
    make -C c colibri olmoe ARCH=x86-64-v3
  '';

  installPhase = ''
    mkdir -p $out/bin $out/libexec/colibri/tools

    # INFO: c/coli resolves the installed bin/libexec layout.
    install -Dm755 c/coli $out/bin/coli
    install -Dm755 c/colibri $out/libexec/colibri/colibri
    install -Dm755 c/olmoe $out/libexec/colibri/olmoe

    install -Dm644 \
      c/family_registry.py \
      c/resource_plan.py \
      c/doctor.py \
      c/autotune.py \
      c/openai_server.py \
      c/cluster.py \
      c/v4_dsml.py \
      c/v41_dsml.py \
      c/version.py \
      -t $out/libexec/colibri

    # FIXME: upstream make install omits v41_dsml.py although openai_server.py imports it.
    cp -R c/tools/. $out/libexec/colibri/tools/

    # INFO: dashboard omitted; it requires a separate web/npm build.
    # TODO: add conversion dependencies only when the conversion workflow is exposed.
  '';

  nativeBuildInputs = [ python3 ];

  meta = {
    description = "Tiny C inference engine for large mixture-of-experts models";
    homepage = "https://github.com/JustVugg/colibri";
    license = lib.licenses.asl20;
    mainProgram = "coli";
    platforms = lib.platforms.linux;
  };
}
