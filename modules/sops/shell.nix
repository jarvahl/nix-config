{ lib, ... }:
{
  perSystem = { pkgs, sopsShellUnlock, ... }: {
    _module.args.sopsShellUnlock = pkgs.writeText "unlock-sops-shell.sh" ''
      encrypted_keys="''${SOPS_KEYS_FILE:-$PWD/breakglass.age}"

      if [ ! -f "$encrypted_keys" ]; then
        echo "missing encrypted SOPS identity: $encrypted_keys" >&2
        return 1
      fi
      if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ]; then
        echo "SOPS shell requires XDG_RUNTIME_DIR and systemd --user" >&2
        return 1
      fi

      shell_identity="$(${pkgs.util-linux}/bin/getino --print-pid "$$")" || return 1
      key_unit="sops-$(< /proc/sys/kernel/random/uuid)"

      if ! ${pkgs.systemd}/bin/systemd-run --user --quiet --collect \
        --unit="$key_unit" \
        --service-type=exec \
        --property="RuntimeDirectory=$key_unit" \
        --property=RuntimeDirectoryMode=0700 \
        ${pkgs.util-linux}/bin/waitpid --exited "$shell_identity"
      then
        return 1
      fi

      key="$XDG_RUNTIME_DIR/$key_unit/key"
      if ! (
        umask 077
        ${pkgs.age}/bin/age -d "$encrypted_keys" > "$key"
      ) || ! ${pkgs.age}/bin/age-keygen -y "$key" >/dev/null; then
        echo "failed to unlock recovery identity" >&2
        ${pkgs.systemd}/bin/systemctl --user stop "$key_unit"
        return 1
      fi

      export SOPS_AGE_KEY_FILE="$key"
      export SOPS_SHELL_KEY_NAME=breakglass
      echo "using breakglass identity from $encrypted_keys"
    '';

    apps.write-host-key = {
      meta.description = "Install a host age key from its encrypted key.age file";
      type = "app";
      program = lib.getExe (
        pkgs.writeShellApplication {
          name = "write-host-key";
          runtimeInputs = [ pkgs.age ];
          text = ''
            set -euo pipefail

            if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
              echo "usage: nix run .#write-host-key [-- hostname]"
              echo "installs a host age key from modules/den/aspects/<host>+/key.age"
              echo
              echo "without an explicit hostname, uses: $(hostname)"
              exit 0
            fi

            host="''${1:-$(hostname)}"
            key_file="''${HOST_KEY_FILE:-modules/den/aspects/''${host}+/key.age}"
            target="/var/lib/sops-nix/key.txt"

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
