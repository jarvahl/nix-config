{
  inputs,
  lib,
  recovery,
  ...
}:
{
  git.ignore = [
    "/.terraform/"
    "/config.tf.json"
    "/terraform.tfstate"
    "/terraform.tfstate.backup"
  ];

  imports = [ inputs.terranix.flakeModule ];

  perSystem =
    { pkgs, self', ... }:
    let
      exportSecrets = pkgs.writeText "terranix-export-secrets.sh" ''
        secrets="$PWD/terranix.sops.yaml"
        declare -A seen=()
        while IFS= read -r -d "" key && IFS= read -r -d "" value; do
          if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ || -v "seen[$key]" ]]; then
            printf 'Invalid or duplicate SOPS environment name\n' >&2
            return 1
          fi
          seen["$key"]=1
          export "$key=$value" 2>/dev/null || return 1
        done < <(
          set -o pipefail
          ${pkgs.sops}/bin/sops -d --output-type json "$secrets" |
            ${pkgs.jq}/bin/jq -j '
              paths(type != "object" and type != "array") as $p
              | ($p | map(tostring | ascii_upcase) | join("_")), (getpath($p) | tostring)
              | if contains("\u0000") then error("NUL in SOPS environment") else ., "\u0000" end
            '
        )
        # Process substitution does not propagate the pipeline status to the loop.
        wait "$!" || return
        unset key value secrets seen
      '';
    in
    {
      terranix.exportDevShells = false;

      apps.sops-import-from-terranix = {
        meta.description = "Import Terranix SOPS outputs into encrypted SOPS files";
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "sops-import-from-terranix";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.jq
              pkgs.opentofu
              pkgs.sops
            ];
            text = ''
              set -euo pipefail

              if [ "''${SOPS_SHELL_KEY_NAME:-}" != recovery ] || [ ! -r "''${SOPS_AGE_KEY_FILE:-}" ]; then
                printf 'Run this command inside: nix develop .#sops\n' >&2
                exit 1
              fi

              root="$(git rev-parse --show-toplevel)"
              cd "$root"
              encrypted_state="$root/terraform.tfstate.sops.json"
              if [ ! -f "$encrypted_state" ]; then
                printf 'Missing encrypted Terranix state: %s\n' "$encrypted_state" >&2
                exit 1
              fi

              temporary="$(mktemp -d)"
              chmod 0700 "$temporary"
              trap 'rm -rf -- "$temporary"' EXIT
              state="$temporary/terraform.tfstate"
              sops -d "$encrypted_state" > "$state"
              chmod 0600 "$state"
              outputs="$(cd "$temporary" && tofu output -json)"

              count=0
              while IFS=$'\t' read -r name value; do
                [ -n "$name" ] || continue
                if [[ "$name" != sops__* ]]; then
                  printf 'Invalid SOPS output name: %s\n' "$name" >&2
                  exit 1
                fi
                remaining="''${name#sops__}"
                if [[ "$remaining" != *__* ]]; then
                  printf 'Invalid SOPS output name: %s\n' "$name" >&2
                  exit 1
                fi
                aspect="''${remaining%%__*}"
                remaining="''${remaining#*__}"
                if [[ "$remaining" != *__* ]]; then
                  printf 'Invalid SOPS output name: %s\n' "$name" >&2
                  exit 1
                fi
                entity="''${remaining%%__*}"
                key_path="''${remaining#*__}"
                if [[ ! "$aspect" =~ ^[a-zA-Z0-9_-]+$ || ! "$entity" =~ ^[a-zA-Z0-9_-]+$ || "$entity" == *__* || ! "$key_path" =~ ^[a-zA-Z0-9_-]+(__[a-zA-Z0-9_-]+)*$ ]]; then
                  printf 'Invalid SOPS output name: %s\n' "$name" >&2
                  exit 1
                fi
                if [ "$entity" = host ]; then
                  target="modules/den/aspects/''${aspect}+/host.sops.yaml"
                else
                  target="modules/den/aspects/''${aspect}+/user-''${entity}.sops.yaml"
                fi
                if [ ! -f "$target" ]; then
                  printf 'SOPS output target does not exist: %s\n' "$target" >&2
                  exit 1
                fi

                path=""
                remaining="$key_path"
                while [[ "$remaining" == *__* ]]; do
                  segment="''${remaining%%__*}"
                  [ -n "$segment" ] || { printf 'Empty SOPS key segment in output: %s\n' "$name" >&2; exit 1; }
                  encoded="$(printf '%s' "$segment" | jq -Rr @json)"
                  path+="[$encoded]"
                  remaining="''${remaining#*__}"
                done
                [ -n "$remaining" ] || { printf 'Empty SOPS key segment in output: %s\n' "$name" >&2; exit 1; }
                encoded="$(printf '%s' "$remaining" | jq -Rr @json)"
                path+="[$encoded]"

                directory="$(dirname "$target")"
                temporary_file="$(mktemp "$directory/.sops-import.XXXXXX.yaml")"
                cp -- "$target" "$temporary_file"
                if ! printf '%s' "$value" | sops set --idempotent --value-stdin "$temporary_file" "$path" >/dev/null; then
                  rm -f -- "$temporary_file"
                  exit 1
                fi
                if ! cmp -s "$target" "$temporary_file"; then
                  chmod --reference="$target" "$temporary_file"
                  mv -- "$temporary_file" "$target"
                else
                  rm -f -- "$temporary_file"
                fi
                count=$((count + 1))
              done < <(jq -r 'to_entries[] | select(.key | startswith("sops__")) | [.key, (.value.value | tojson)] | @tsv' <<< "$outputs")

              printf 'Imported %s Terranix output(s) into SOPS.\n' "$count"
            '';
          }
        );
      };

      terranix.terranixConfigurations.terranix = {
        terraformWrapper = {
          extraRuntimeInputs = [
            pkgs.jq
            pkgs.sops
          ];
          package = pkgs.opentofu.withPlugins (plugins: [
            plugins.hashicorp_random
            plugins.tailscale_tailscale
            self'.packages.terraform-provider-matrix
          ]);
          prefixText = ''
            if [ "''${SOPS_SHELL_KEY_NAME:-}" != recovery ] || [ ! -r "''${SOPS_AGE_KEY_FILE:-}" ]; then
              printf 'Run this command inside: nix develop .#sops\n' >&2
              exit 1
            fi
            # shellcheck source=/dev/null
            source ${exportSecrets} || exit 1

            state="$PWD/terraform.tfstate.sops.json"

            if [ -f "$state" ] && sops -d "$state" | jq -e 'has("version")' >/dev/null; then
              sops -d "$state" > terraform.tfstate
            fi

            cleanup() {
              status="$?"
              if [ -f terraform.tfstate ]; then
                sops --encrypt --filename-override "$state" terraform.tfstate > "$state.tmp"
                mv "$state.tmp" "$state"
                rm -f terraform.tfstate
              fi
              exit "$status"
            }

            trap cleanup EXIT
          '';
        };

        workdir = ".";
      };
    };

  sopsFile.creation_rules = recovery [
    {
      key_groups = [
        { age = [ ]; }
      ];
      path_regex = "terranix\\.sops\\.yaml$";
    }
    {
      key_groups = [
        { age = [ ]; }
      ];
      path_regex = "terraform\\.tfstate\\.sops\\.json$";
    }
  ];
}
