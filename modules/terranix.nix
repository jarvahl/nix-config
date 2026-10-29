{
  inputs,
  recovery,
  ...
}:
{
  gitignore.patterns = [
    "/.terraform/"
    "/config.tf.json"
    "/terraform.tfstate"
    "/terraform.tfstate.backup"
  ];

  imports = [ inputs.terranix.flakeModule ];

  perSystem =
    { pkgs, ... }:
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

      terranix.terranixConfigurations.terranix = {
        terraformWrapper = {
          extraRuntimeInputs = [
            pkgs.jq
            pkgs.sops
          ];
          package = pkgs.opentofu;
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
