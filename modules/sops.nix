{
  inputs,
  lib,
  recovery,
  ...
}:
lib.mkMerge [
  {
    readme-file.sections = lib.mkOrder 400 [
      {
        title = "SOPS recovery shell";
        text = ''
          Unlock an encrypted recovery age identity for SOPS:

          ```sh
          nix develop .#sops
          ```

          By default it reads `./sops-keys.age` and unlocks the `recovery` key. Override with:

          ```sh
          SOPS_KEYS_FILE=/path/to/sops-keys.age SOPS_KEY_NAME=terranix nix develop .#sops
          ```
        '';
      }
    ];

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
      apps.pair = {
        meta.description = "Pair a host with its age key from keys.yaml";
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "pair";
            runtimeInputs = [ pkgs.sops ];
            text = ''
              set -euo pipefail

              if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
                echo "usage: nix run .#pair [-- hostname]"
                echo "installs host age key from keys.yaml to /var/lib/sops-nix/key.txt"
                echo
                echo "without an explicit hostname, uses: $(hostname)"
                exit 0
              fi

              host="''${1:-$(hostname)}"
              secrets_file="''${PAIR_KEYS_FILE:-keys.yaml}"
              target="/var/lib/sops-nix/key.txt"

              if [ ! -f "''${secrets_file}" ]; then
                echo "missing pair keys file: ''${secrets_file}" >&2
                echo "run from the repository root or set PAIR_KEYS_FILE" >&2
                exit 1
              fi

              tmp="$(mktemp)"
              trap 'rm -f "$tmp"' EXIT

              if ! sops -d --extract "[\"''${host}\"][\"age\"]" "''${secrets_file}" > "$tmp"; then
                echo "failed to decrypt age key for host: ''${host}" >&2
                echo "if this machine hostname is not the target host, pass it explicitly:" >&2
                echo "  nix run .#pair -- <hostname>" >&2
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

              echo "paired host ''${host} with its age key at ''${target}"
            '';
          }
        );
      };

      devShells.sops = pkgs.mkShell {
        packages = [
          pkgs.age
          pkgs.sops
          pkgs.yq-go
        ];

        shellHook = ''
          encrypted_keys="''${SOPS_KEYS_FILE:-$PWD/sops-keys.age}"
          key_name="''${SOPS_KEY_NAME:-recovery}"

          if [ ! -f "$encrypted_keys" ]; then
            echo "missing SOPS key bundle: $encrypted_keys" >&2
            echo "set SOPS_KEYS_FILE=/path/to/sops-keys.age" >&2
            return 1
          fi

          key="$(mktemp)"
          if ! age -d "$encrypted_keys" | yq -r ".''${key_name}" > "$key"; then
            rm -f "$key"
            return 1
          fi

          if ! grep -q '^AGE-SECRET-KEY-' "$key"; then
            echo "missing age identity: $key_name" >&2
            rm -f "$key"
            return 1
          fi

          chmod 600 "$key"
          export SOPS_AGE_KEY_FILE="$key"

          cleanup_sops_recovery() {
            rm -f "$SOPS_AGE_KEY_FILE"
          }
          trap cleanup_sops_recovery EXIT

          echo "sops shell active"
          echo "using key: $key_name from $encrypted_keys"
        '';
      };
    };
  }
  {
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
  }
]
