{ inputs, lib, ... }:
{
  den.default.nixos = {
    hjem.extraModules = [ inputs.sops-nix.homeManagerModules.sops ];
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  flake-file.inputs.sops-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };

}
// {
  perSystem = { pkgs, sopsShellUnlock, ... }: {
    _module.args.sopsShellUnlock = pkgs.writeText "unlock-sops-shell.sh" ''
      encrypted_keys="''${SOPS_KEYS_FILE:-$PWD/breakglass.age}"
      runtime_dir="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}"
      key="$(mktemp "$runtime_dir/sops-key.XXXXXX")"

      cleanup() {
        rm -f "$key"
      }

      trap cleanup EXIT HUP INT TERM
      umask 077

      if [ ! -f "$encrypted_keys" ]; then
        echo "missing encrypted SOPS identity: $encrypted_keys" >&2
        return 1
      fi

      if ! ${pkgs.age}/bin/age -d "$encrypted_keys" > "$key"; then
        echo "failed to unlock breakglass identity" >&2
        return 1
      fi

      if ! ${pkgs.age}/bin/age-keygen -y "$key" >/dev/null; then
        echo "decrypted value is not an age identity" >&2
        return 1
      fi

      export SOPS_AGE_KEY_FILE="$key"
      export SOPS_SHELL_KEY_NAME=breakglass
      echo "using breakglass identity from $encrypted_keys"
    '';

    apps.write-host-key = {
      meta.description = "Install a host age key from its encrypted key.age file";
      program = lib.getExe (
        pkgs.writeShellApplication {
          name = "write-host-key";
          runtimeInputs = [ pkgs.age ];
          text = ''
            set -euo pipefail

            if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
              echo "usage: nix run .#write-host-key [-- hostname]"
              echo "installs a host age key from modules/+configurations/den/aspects/<host>/key.age"
              echo
              echo "without an explicit hostname, uses: $(hostname)"
              exit 0
            fi

            host="''${1:-$(hostname)}"
            key_file="''${HOST_KEY_FILE:-modules/+configurations/den/aspects/''${host}+/key.age}"
            target="/var/lib/sops-outputs/key.txt"

            if [ -z "''${SOPS_AGE_KEY_FILE:-}" ] || [ ! -r "''${SOPS_AGE_KEY_FILE}" ]; then
              echo "missing unlocked breakglass identity; run: nix develop .#sops" >&2
              exit 1
            fi

            if [ ! -f "''${key_file}" ]; then
              echo "missing encrypted host key: ''${key_file}" >&2
              exit 1
            fi

            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            umask 077

            if ! age -d -i "''${SOPS_AGE_KEY_FILE}" "''${key_file}" > "$tmp"; then
              echo "failed to decrypt host key: ''${key_file}" >&2
              exit 1
            fi

            if ! grep -q '^AGE-SECRET-KEY-' "$tmp"; then
              echo "decrypted value does not look like an age secret key" >&2
              exit 1
            fi

            if [ "$(id -u)" -eq 0 ]; then
              install -D -m 0600 -o root -g root "$tmp" "''${target}"
            else
              sudo install -D -m 0600 -o root -g root "$tmp" "''${target}"
            fi

            echo "installed host age key for ''${host} at ''${target}"
          '';
        }
      );
      type = "app";
    };

    devShells.sops = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.sops
      ];

      shellHook = ''
        source ${sopsShellUnlock} || exit 1
        echo "sops shell active"
      '';
    };
  };
}
