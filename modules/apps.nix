{ lib, ... }:
{
  perSystem = { pkgs, ... }: {
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
              echo "installs a host age key from modules/+configurations/aspects/<host>/key.age"
              echo
              echo "without an explicit hostname, uses: $(hostname)"
              exit 0
            fi

            host="''${1:-$(hostname)}"
            key_file="''${HOST_KEY_FILE:-modules/+configurations/aspects/''${host}+/key.age}"
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

  };
}
