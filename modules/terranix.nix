{
  config,
  inputs,
  lib,
  recovery,
  ...
}:
let
  servicesByHost = lib.mapAttrs (
    _host: nixos: nixos.config.services.tailscale.services or { }
  ) config.flake.nixosConfigurations;
in
{
  imports = [ inputs.terranix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      terranix.terranixConfigurations.terranix = {
        extraArgs.servicesByHost = servicesByHost;

        modules = [
          (inputs.import-tree.initFilter (lib.hasInfix "/_terranix/") ./den/aspects)
        ];

        terraformWrapper = {
          extraRuntimeInputs = [
            pkgs.age
            pkgs.sops
          ];
          package = pkgs.opentofu;
          prefixText = ''
            if [ -z "''${SOPS_AGE_KEY_FILE:-}" ]; then
              echo "enter nix develop .#sops first" >&2
              exit 1
            fi

            state="$PWD/../state.sops.json"
            secrets="$PWD/../secrets.yaml"

            if [ -f "$state" ]; then
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

        workdir = ".terranix";
      };
    };

  sopsFile.creation_rules = recovery [
    {
      key_groups = [
        { age = [ "recovery" ]; }
      ];
      path_regex = "state\\.sops\\.json$";
    }
  ];
}
