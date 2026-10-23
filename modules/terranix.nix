{
  inputs,
  lib,
  recovery,
  ...
}:
{
  imports = [ inputs.terranix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      terranix.terranixConfigurations.terranix = {
        modules = [
          (inputs.import-tree.initFilter (lib.hasInfix "/_terranix/") ./den/aspects)
        ];

        terraformWrapper = {
          extraRuntimeInputs = [
            pkgs.age
            pkgs.jq
            pkgs.sops
            pkgs.yq-go
          ];
          package = pkgs.opentofu;
          prefixText = ''
            temporary_key_dir="$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/terranix.XXXXXX")"
            temporary_key="$temporary_key_dir/key"
            if ! age -d "$PWD/sops-keys.age" | yq -r '.terranix' > "$temporary_key"; then
              rm -rf "$temporary_key_dir"
              exit 1
            fi
            chmod 600 "$temporary_key"
            export SOPS_AGE_KEY_FILE="$temporary_key"

            cleanup_key() {
              rm -rf "$temporary_key_dir"
            }
            trap cleanup_key EXIT

            state="$PWD/terraform.tfstate.sops.json"
            secrets="$PWD/secrets.yaml"

            if [ -f "$state" ] && sops -d "$state" | jq -e 'has("version")' >/dev/null; then
              sops -d "$state" > terraform.tfstate
            fi

            TAILSCALE_API_KEY="$(
              sops -d --extract '["tailscale"]["api_key"]' "$secrets"
            )"
            export TAILSCALE_API_KEY

            cleanup() {
              status="$?"
              if [ -f terraform.tfstate ]; then
                sops --encrypt --filename-override "$state" terraform.tfstate > "$state.tmp"
                mv "$state.tmp" "$state"
                rm -f terraform.tfstate
              fi
              rm -rf "$temporary_key_dir"
              exit "$status"
            }

            trap cleanup EXIT
          '';
        };

        workdir = ".";
      };
    };

  sopsFile = {
    creation_rules = [
      {
        key_groups = [
          { age = [ "terranix" ]; }
        ];
        path_regex = "secrets\\.yaml$";
      }
      {
        key_groups = [
          { age = [ "terranix" ]; }
        ];
        path_regex = "terraform\\.tfstate\\.sops\\.json$";
      }
    ];
    keys.terranix = "age1jxpxeqkdvp0s8784yntutpxw9k8a6428hq6vc3tvjgl5kqjf856qefv7m4";
  };
}
