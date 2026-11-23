{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.files.url = "github:mightyiam/files";
  flake-file.inputs.sops-file.url = "github:jarvahl/sops-file";

  imports = [
    "${inputs.files.outPath}/flake-module.nix"
    inputs.sops-file.flakeModules.default
  ];

  perSystem =
    {
      config,
      pkgs,
      sopsShellUnlock,
      ...
    }:
    {
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
      apps.write-files = {
        program = lib.mkForce (
          lib.getExe (
            pkgs.writeShellApplication {
              name = "write-files";
              runtimeInputs = [ pkgs.gitMinimal ];
              text = ''
                cd "$(git rev-parse --show-toplevel)"
                ${lib.getExe config.packages.write-flake}
                exec ${lib.getExe config.files.writer.drv}
              '';
            }
          )
        );
        type = "app";
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          age
          just
          runme
          sops
        ];

        shellHook = ''
          ${config.pre-commit.shellHook}
        '';
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
