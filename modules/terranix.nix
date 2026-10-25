{
  inputs,
  lib,
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
    {
      config,
      pkgs,
      sopsShellUnlock,
      ...
    }:
    {
      devShells.terranix = lib.mkForce (
        config.terranix.terranixConfigurations.terranix.result.devShell.overrideAttrs (old: {
          shellHook = (old.shellHook or "") + ''
            source ${sopsShellUnlock} || exit 1
          '';
        })
      );

      terranix.terranixConfigurations.terranix = {
        modules = [
          (inputs.import-tree.initFilter (lib.hasInfix "/_terranix/") ./den/aspects)
        ];

        terraformWrapper = {
          extraRuntimeInputs = [
            pkgs.jq
            pkgs.sops
          ];
          package = pkgs.opentofu;
          prefixText = ''
            if [ "''${SOPS_SHELL_KEY_NAME:-}" != recovery ] || [ ! -r "''${SOPS_AGE_KEY_FILE:-}" ]; then
              # shellcheck source=/dev/null
              source ${sopsShellUnlock} || exit 1
            fi

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
      path_regex = "secrets\\.yaml$";
    }
    {
      key_groups = [
        { age = [ ]; }
      ];
      path_regex = "terraform\\.tfstate\\.sops\\.json$";
    }
  ];
}
