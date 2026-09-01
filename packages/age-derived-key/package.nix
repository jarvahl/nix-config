{ python3, writeShellApplication }:

let
  python = python3.withPackages (ps: [
    ps.argon2-cffi
    ps.bech32
  ]);
in
writeShellApplication {
  name = "age-derived-key";

  runtimeInputs = [ python ];

  text = ''
    exec python3 ${./age-derived-key.py} "$@"
  '';
}
