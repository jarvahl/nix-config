{ inputs, lib, ... }:
{
  readme-file.sections = lib.mkOrder 400 [
    {
      title = "SOPS recovery shell";
      text = ''
        Unlock an encrypted recovery age identity for SOPS:

        ```sh
        nix develop .#sops-recovery
        ```

        By default it reads `./recovery.key.age`. Override with:

        ```sh
        SOPS_RECOVERY_KEY=/path/to/recovery.key.age nix develop .#sops-recovery
        ```
      '';
    }
  ];

  agent-files.skills.sops = {
    description = "Use when managing SOPS secrets, age keys, or recovery in this repository; not for general encryption.";
    instructions = { references, ... }: ''
      # SOPS

      Use this skill for SOPS maintenance in this repo.

      ## Routing

      | Task | Read |
      | --- | --- |
      | Creating or rotating the passphrase-encrypted recovery age identity | `${references.create-recovery-key}` |
      | Unsure | Start with `${references.create-recovery-key}` |

      Keep this file light. Detailed runbooks live in `references/`.
    '';
    references.create-recovery-key = {
      description = "Create SOPS recovery key";
      text = ''
        # Create SOPS recovery key

        Generate age identity:

        ```shell
        age-keygen -o recovery.key
        ```

        Encrypt it with a passphrase:

        ```shell
        age -p -a -o recovery.key.age recovery.key
        ```

        Show public recipient if you later want to add it to SOPS rules:

        ```shell
        age-keygen -y recovery.key
        ```

        Remove plaintext identity:

        ```shell
        rm recovery.key
        ```

        This creates `recovery.key.age`: a passphrase-encrypted age identity safe to keep in the repo.
      '';
    };
  };

  den.default.nixos = {
    hjem.extraModules = [ inputs.sops-nix.homeManagerModules.sops ];
    imports = [ inputs.sops-nix.nixosModules.sops ];
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  flake-file.inputs.sops-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };

  perSystem = { pkgs, ... }: {
    apps.bootstrap = {
      meta.description = "Install a host age key from secrets-bootstrap.yaml";
      type = "app";
      program = lib.getExe (
        pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.sops ];
          text = ''
            set -euo pipefail

            if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
              echo "usage: nix run .#bootstrap [-- hostname]"
              echo "installs host age key from secrets-bootstrap.yaml to /var/lib/sops-nix/key.txt"
              echo
              echo "without an explicit hostname, uses: $(hostname)"
              exit 0
            fi

            host="''${1:-$(hostname)}"
            secrets_file="''${BOOTSTRAP_SECRETS_FILE:-secrets-bootstrap.yaml}"
            target="/var/lib/sops-nix/key.txt"

            if [ ! -f "''${secrets_file}" ]; then
              echo "missing bootstrap secrets file: ''${secrets_file}" >&2
              echo "run from the repository root or set BOOTSTRAP_SECRETS_FILE" >&2
              exit 1
            fi

            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT

            if ! sops -d --extract "[\"hosts\"][\"''${host}\"][\"age_key\"]" "''${secrets_file}" > "$tmp"; then
              echo "failed to decrypt bootstrap key for host: ''${host}" >&2
              echo "if this machine hostname is not the target host, pass it explicitly:" >&2
              echo "  nix run .#bootstrap -- <hostname>" >&2
              exit 1
            fi

            if ! grep -q '^AGE-SECRET-KEY-' "$tmp"; then
              echo "decrypted value for host ''${host} does not look like an age secret key" >&2
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

    devShells.sops-recovery = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.sops
      ];

      shellHook = ''
        encrypted_key="''${SOPS_RECOVERY_KEY:-$PWD/recovery.key.age}"

        if [ ! -f "$encrypted_key" ]; then
          echo "missing recovery key: $encrypted_key" >&2
          echo "set SOPS_RECOVERY_KEY=/path/to/recovery.key.age" >&2
          return 1
        fi

        key="$(mktemp)"
        if ! age -d -o "$key" "$encrypted_key"; then
          rm -f "$key"
          return 1
        fi

        chmod 600 "$key"
        export SOPS_AGE_KEY_FILE="$key"

        cleanup_sops_recovery() {
          rm -f "$SOPS_AGE_KEY_FILE"
        }
        trap cleanup_sops_recovery EXIT

        echo "sops recovery shell active"
        echo "using encrypted key: $encrypted_key"
      '';
    };
  };

}
