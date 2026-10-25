{
  checkedPath,
  inputs,
  lib,
  ...
}:
lib.mkMerge [
  {
    gitignore.patterns = [
      "recovery.key"
      ".keys/"
    ];

    readme-file.sections = lib.mkOrder 400 [
      {
        title = "SOPS recovery shell";
        text = ''
          Unlock an encrypted recovery age identity for SOPS:

          ```sh
          nix develop .#sops
          ```

          By default it unlocks the recovery identity from `./breakglass.age`. Override with:

          ```sh
          SOPS_KEYS_FILE=/path/to/breakglass.age nix develop .#sops
          ```

          `nix develop .#terranix` unlocks the same recovery identity on entry, too.
          Both shells require Linux with a running systemd user manager. Each session
          gets a private runtime directory, removed by systemd when its shell exits,
          including after SIGKILL. Terranix commands reuse the shell's unlocked key.
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
        export SOPS_SHELL_KEY_NAME=recovery
        echo "using recovery identity from $encrypted_keys"
      '';

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
        ];

        shellHook = ''
          source ${sopsShellUnlock} || exit 1
          echo "sops shell active"
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
        | Declaring secrets, choosing host/user context, or wiring a consumer | `${references.secrets}` |
        | Creating or rotating the passphrase-encrypted recovery identity | `${references.create-recovery-key}` |
        | Unsure | Start with `${references.secrets}` |

        Keep this file light. Detailed runbooks live in `references/`.
      '';
      references.create-recovery-key = {
        description = "Create recovery identity";
        text = ''
          # Create recovery identity

          `breakglass.age` contains one raw age recovery identity, encrypted with a
          passphrase. Both the SOPS and Terranix shells use it; there is no separate
          Terranix identity or YAML key bundle.

          Encrypt an existing recovery identity from a private runtime file:

          ```shell
          age -p -a -o breakglass.age "$SOPS_AGE_KEY_FILE"
          ```

          Verify the encrypted identity before removing the plaintext copy or an
          older encrypted copy. Never replace the existing recovery identity without
          first migrating and verifying every encrypted file that depends on it.

          `nix develop .#sops` and `nix develop .#terranix` unlock it into a private
          runtime directory. A systemd user service waits for the shell via pidfd
          and removes the directory when the shell exits, including after SIGKILL.
          Unlocking it grants access to all recovery-protected secrets.
        '';
      };
      references.secrets = {
        description = "Declare and consume SOPS secrets";
        text = ''
          # Declare and consume SOPS secrets

          Use the current helpers in `${checkedPath ./den/aspects/sops.nix}`:

          - `from file` selects the encrypted YAML file.
          - `keyFile path` selects the age identity used for decryption.
          - `secret params aspect` declares a secret and includes its consuming aspect.
            The second argument is required; use `{ }` when consumption is configured elsewhere.

          ## User secrets

          Declare these in the user's aspect, such as `jarvahl@dvalin`, not the host aspect:

          ```nix
          includes = with den.aspects.sops; [
            (from ./secrets-user-jarvahl.yaml)
            (keyFile ".config/sops/age/key.txt")
            (secret {
              name = "openclaw/gateway_token";
              path = ".config/openclaw/gateway-token";
            } { })
          ];
          ```

          Relative paths resolve against the user's home directory. `keyFile` also declares
          the host-side `users/<user>/age_key` secret that provisions this identity;
          ensure the host's encrypted file contains it.

          Related declarations may be nested in an application's callable `includes`.
          Keep `from` and `keyFile` in the enclosing user aspect when shared by applications.
          See `${checkedPath ./den/aspects/dvalin+/default.nix}` for OpenClaw and
          `${checkedPath ./den/aspects/github.nix}` for wiring a consumer in the second argument.

          ## Host secrets

          Declare these in the host aspect with a host SOPS file and an absolute key path.
          Use an absolute secret destination; set `owner`, `group`, and `restartUnits`
          when the consuming service requires them. The default mode is `0600`.
          Consume `config.sops.secrets.<name>.path` inside the second argument's `nixos`
          module; user consumers belong in `hjem` modules instead.
          See the Tailscale secret in `${checkedPath ./den/aspects/dvalin+/default.nix}`.

          ## Checks and safety

          Verify the encrypted file contains the requested name and its recipients match
          the intended host/user. Update creation rules through the existing `sopsFile`
          declarations; changing a rule alone does not re-encrypt an existing file.
          Never put decrypted values in Nix expressions, logs, or the Nix store.
          Pass secret paths through the consumer's supported runtime file mechanism.

          Run `nix flake check --no-build` and evaluate the affected secret path and consumer.
          Evaluation cannot verify deployed age keys, decryption, or service startup.
        '';
      };
    };
  }
]
